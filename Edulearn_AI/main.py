import os
from dotenv import load_dotenv
load_dotenv()

# Verify API Key exists
if not os.getenv("GOOGLE_API_KEY") and not os.getenv("GEMINI_API_KEY"):
    print("WARNING: No API Key found in environment variables!")
else:
    print("Environment variables loaded successfully.")

from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel
import uvicorn
import shutil
from document_processor import DocumentProcessor
from vector_store import VectorStoreManager
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.prompts import PromptTemplate
from langchain_community.chat_message_histories import ChatMessageHistory
from langchain_core.messages import HumanMessage, AIMessage

# In-memory store for session histories
session_histories = {}

app = FastAPI(
    title="EduLearn AI API",
    description="API for EduLearn platform to handle AI tasks like RAG and question generation.",
    version="1.0.0"
)

@app.get("/")
def read_root():
    return {"message": "Welcome to EduLearn AI API! The server is running successfully."}

@app.get("/health")
def health_check():
    return {"status": "healthy"}

# Ensure temp directory exists for uploads
UPLOAD_DIR = "temp_uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

processor = DocumentProcessor()
vector_store_manager = VectorStoreManager()

# Initialize Gemini model for Chat
llm = ChatGoogleGenerativeAI(model="gemini-1.5-flash", convert_system_message_to_human=True)

prompt_template = PromptTemplate(
    template="""You are 'EduLearn AI Tutor', a helpful AI assistant for students.
Answer the user's question based strictly on the provided context.
If the answer is not contained in the context, say "I don't have enough information in the course materials to answer that."

Context:
{context}

Question: {question}

Answer:""",
    input_variables=["context", "question"]
)

class ChatRequest(BaseModel):
    message: str
    session_id: str = "default_user"
    context_source: str = None # Optional: limit search to a specific file

class ExerciseRequest(BaseModel):
    content: str = None # If text is provided directly
    filename: str = None # If we should pull from vector store
    count: int = 5
    difficulty: str = "medium" # easy, medium, hard

class AdaptiveRequest(BaseModel):
    student_level: float # 0.0 to 1.0 (proficiency)
    topic: str
    previous_mistakes: list[str] = []

class TeacherReportRequest(BaseModel):
    class_stats: dict
    student_issues: list[dict]
    teacher_name: str

@app.post("/upload-pdf/")
async def upload_pdf(file: UploadFile = File(...)):
    if not file.filename.endswith('.pdf'):
        raise HTTPException(status_code=400, detail="Only PDF files are supported.")
    
    file_path = os.path.join(UPLOAD_DIR, file.filename)
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    try:
        chunks = processor.process_pdf(file_path)
        if chunks:
            vector_store_manager.add_texts(chunks, metadata={"source": file.filename})
        
        # We can also generate an initial set of exercises automatically
        os.remove(file_path)
        return {
            "message": "File processed successfully",
            "filename": file.filename,
            "total_chunks_added": len(chunks)
        }
    except Exception as e:
        if os.path.exists(file_path): os.remove(file_path)
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/generate-exercises/")
async def generate_exercises(request: ExerciseRequest):
    try:
        context = ""
        if request.content:
            context = request.content
        elif request.filename:
            docs = vector_store_manager.search_similar(f"summarize {request.filename}", k=5)
            context = "\n".join([d.page_content for d in docs if d.metadata.get("source") == request.filename])
        
        if not context:
            raise HTTPException(status_code=404, detail="No content found to generate exercises from.")

        prompt = f"""Based on the following educational content, generate {request.count} {request.difficulty} level exercises in Arabic.
        Format the output as a JSON list of objects, each having:
        - question: The exercise text
        - type: 'multiple_choice' or 'true_false'
        - options: List of options (null if true_false)
        - answer: The correct answer
        - explanation: Why this is the correct answer
        
        Content:
        {context[:3000]}
        """
        
        response = llm.invoke(prompt)
        # We expect a JSON string, but LLMs sometimes add markdown. We'll try to clean it.
        content = response.content.replace("```json", "").replace("```", "").strip()
        return {"exercises": content}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/adaptive-content/")
async def get_adaptive_content(request: AdaptiveRequest):
    try:
        level_desc = "Beginner (requires explanation)" if request.student_level < 0.4 else \
                     "Intermediate (standard challenges)" if request.student_level < 0.7 else \
                     "Advanced (complex application)"
        
        prompt = f"""The student's current proficiency in '{request.topic}' is {request.student_level*100}% ({level_desc}).
        They previously struggled with: {', '.join(request.previous_mistakes) if request.previous_mistakes else 'None'}.
        
        Provide a tailored 5-question quiz (in Arabic) that targets their level and addresses their weak points.
        Return in JSON format.
        """
        
        response = llm.invoke(prompt)
        return {"tailored_quiz": response.content.replace("```json", "").replace("```", "").strip()}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/teacher-daily-report/")
async def generate_teacher_report(request: TeacherReportRequest):
    try:
        prompt = f"""Generate a supportive daily analytical report for Teacher {request.teacher_name} in Arabic.
        Class Stats: {request.class_stats}
        Identified Student Issues: {request.student_issues}
        
        Focus on:
        1. General class mood and performance today.
        2. Specific students who need attention or praise.
        3. A pedagogical recommendation for tomorrow's lesson.
        
        Format it professionally as a newsletter.
        """
        
        response = llm.invoke(prompt)
        return {"report": response.content}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/chat/")
async def chat_with_tutor(request: ChatRequest):
    try:
        # 1. Handle Chat Memory
        if request.session_id not in session_histories:
            session_histories[request.session_id] = ChatMessageHistory()
        
        history = session_histories[request.session_id]
        
        # Pull last few messages for context
        past_messages = history.messages[-10:] if len(history.messages) > 10 else history.messages
        chat_history_str = "\n".join([f"{'User' if isinstance(m, HumanMessage) else 'AI'}: {m.content}" for m in past_messages])

        # 2. Search for relevant context
        docs = vector_store_manager.search_similar(request.message, k=3)
        context = "\n\n".join([doc.page_content for doc in docs])
        
        if not context.strip():
            context = "No specific source context available for this question."

        # 3. Build Enhanced Prompt
        prompt = f"""You are 'EduLearn AI Tutor'. Follow the school curriculum.
        Use the context below AND the chat history to answer.
        
        CONTEXT FROM MATERIALS:
        {context}
        
        RECENT CHAT HISTORY:
        {chat_history_str}
        
        USER QUESTION: {request.message}
        
        ANSWER (in Arabic):"""

        # 4. Generate response
        response = llm.invoke(prompt)
        ai_reply = response.content
        
        # 5. Save to history
        history.add_user_message(request.message)
        history.add_ai_message(ai_reply)
        
        return {
            "reply": ai_reply,
            "session_id": request.session_id,
            "sources": [doc.metadata.get("source", "Unknown") for doc in docs]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)
