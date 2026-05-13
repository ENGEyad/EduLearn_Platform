import os
import shutil
import json

from dotenv import load_dotenv
from fastapi import FastAPI, File, HTTPException, UploadFile
from langchain_community.chat_message_histories import ChatMessageHistory
from langchain_core.messages import AIMessage, HumanMessage
from langchain_core.prompts import PromptTemplate
from langchain_google_genai import ChatGoogleGenerativeAI
from pydantic import BaseModel
import uvicorn

from document_processor import DocumentProcessor
from vector_store import VectorStoreManager

load_dotenv()


def first_non_empty(*values):
    for value in values:
        if isinstance(value, str) and value.strip():
            return value.strip()
    return None


GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
ACTIVE_API_KEY = first_non_empty(GEMINI_API_KEY, GOOGLE_API_KEY)
CHAT_MODEL = os.getenv("GEMINI_CHAT_MODEL", "gemini-flash-latest")

if not ACTIVE_API_KEY:
    print("WARNING: No Gemini API key found in environment variables.")
else:
    # Diagnostic prints removed
    pass


session_histories = {}

app = FastAPI(
    title="EduLearn AI API",
    description="API for EduLearn platform to handle AI tasks like RAG and question generation.",
    version="1.0.0",
)


@app.get("/")
def read_root():
    return {"message": "Welcome to EduLearn AI API! The server is running successfully."}


@app.get("/health")
def health_check():
    return {"status": "healthy"}


UPLOAD_DIR = "temp_uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

processor = DocumentProcessor()
vector_store_manager = VectorStoreManager(api_key=ACTIVE_API_KEY)

llm = None
import google.generativeai as genai

if ACTIVE_API_KEY:
    os.environ["GOOGLE_API_KEY"] = ACTIVE_API_KEY
    genai.configure(api_key=ACTIVE_API_KEY)
    llm = ChatGoogleGenerativeAI(
        model=CHAT_MODEL,
        google_api_key=ACTIVE_API_KEY,
        convert_system_message_to_human=True,
    )

@app.on_event("startup")
async def startup_event():
    print("\n--- AI Startup Diagnostic ---")
    if ACTIVE_API_KEY:
        try:
            import google.generativeai as genai
            genai.configure(api_key=ACTIVE_API_KEY)
            models = [m.name for m in genai.list_models() if 'generateContent' in m.supported_generation_methods]
            print(f"Available models for this key: {models}")
            print(f"Current model in use: {CHAT_MODEL}")
        except Exception as e:
            print(f"Failed to list models: {e}")
    else:
        print("No API key configured.")
    print("-----------------------------\n")





def ensure_ai_ready() -> None:
    if not ACTIVE_API_KEY or llm is None:
        raise RuntimeError("No Gemini API key is configured. Set GEMINI_API_KEY or GOOGLE_API_KEY.")


prompt_template = PromptTemplate(
    template="""You are 'EduLearn AI Tutor', a helpful AI assistant for students.
Answer the user's question based strictly on the provided context.
If the answer is not contained in the context, say "I don't have enough information in the course materials to answer that."

Context:
{context}

Question: {question}

Answer:""",
    input_variables=["context", "question"],
)


class ChatRequest(BaseModel):
    message: str
    session_id: str = "default_user"
    context_source: str = None


class ExerciseRequest(BaseModel):
    content: str = None
    filename: str = None
    count: int = 5
    difficulty: str = "medium"


class AdaptiveRequest(BaseModel):
    student_level: float
    topic: str
    previous_mistakes: list[str] = []


class TeacherReportRequest(BaseModel):
    class_stats: dict
    student_issues: list[dict]
    teacher_name: str


class DashboardInsightRequest(BaseModel):
    school_name: str | None = None
    period: str
    metrics: dict
    trends: dict = {}
    risks: list[str] = []
    anomalies: list[str] = []
    recommended_focus: list[str] = []
    data_limitations: list[str] = []

class AnalyticsReportRequest(BaseModel):
    system_prompt: str
    data: dict
    model: str = "gemini-flash-latest"

class PromptRequest(BaseModel):
    prompt: str
    model: str = "gemini-flash-latest"


@app.post("/upload-pdf/")
async def upload_pdf(file: UploadFile = File(...)):
    if not file.filename.endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Only PDF files are supported.")

    file_path = os.path.join(UPLOAD_DIR, file.filename)

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    try:
        chunks = processor.process_pdf(file_path)
        if chunks:
            vector_store_manager.add_texts(chunks, metadata={"source": file.filename})

        os.remove(file_path)
        return {
            "message": "File processed successfully",
            "filename": file.filename,
            "total_chunks_added": len(chunks),
        }
    except Exception as e:
        if os.path.exists(file_path):
            os.remove(file_path)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/generate-exercises/")
async def generate_exercises(request: ExerciseRequest):
    try:
        ensure_ai_ready()
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
        content = response.content.replace("```json", "").replace("```", "").strip()
        return {"exercises": content}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/adaptive-content/")
async def get_adaptive_content(request: AdaptiveRequest):
    try:
        ensure_ai_ready()
        level_desc = (
            "Beginner (requires explanation)"
            if request.student_level < 0.4
            else "Intermediate (standard challenges)"
            if request.student_level < 0.7
            else "Advanced (complex application)"
        )

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
        ensure_ai_ready()
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


@app.post("/dashboard-insight/")
async def generate_dashboard_insight(request: DashboardInsightRequest):
    try:
        ensure_ai_ready()
        if ACTIVE_API_KEY:
            os.environ["GOOGLE_API_KEY"] = ACTIVE_API_KEY
        payload_json = json.dumps(request.model_dump(), ensure_ascii=False, indent=2)
        prompt = f"""You are a senior educational performance analyst writing a concise executive dashboard brief for school administrators.

Use only the structured analytics JSON below to generate your brief and the UI data.
Do not invent facts, causes, percentages, trends, or comparisons that are not explicitly present.
If a trend is unavailable or the data is limited, state that clearly and professionally.
Return the full answer in Arabic.
Keep the answer between 120 and 180 words.
Avoid generic AI wording.

Required structure:
Overall Status: ...
Key Insights:
- ...
- ...
Risks:
- ...
Recommended Action: ...

After your text response, you MUST provide a JSON block enclosed in <data> tags for the dashboard UI components.
The JSON must follow this exact structure:
<data>
{{
  "health": [
    {{ "indicator": "Staff Availability", "status": "Optimal/Warning/Critical", "progress": int }},
    {{ "indicator": "Unassigned Students", "status": "Optimal/Warning/Critical", "progress": int }},
    {{ "indicator": "Academic Progress", "status": "Optimal/Stable/Critical", "progress": int }}
  ],
  "distribution": {{
    "labels": ["Section Name", ...],
    "values": [count, ...]
  }}
}}
</data>

Structured analytics JSON:
{payload_json}
"""

        response = llm.invoke(prompt)
        return {"reply": response.content.strip()}
    except Exception as e:
        error_msg = str(e)
        print(f"--- DASHBOARD INSIGHT ERROR ---")
        print(f"Error Type: {type(e).__name__}")
        print(f"Error Message: {error_msg}")
        print(f"-------------------------------")

        if "403" in error_msg or "leaked" in error_msg.lower():
            detail = "Critical: The configured Gemini API key has been revoked or reported as leaked."
        elif "404" in error_msg or "not found" in error_msg.lower():
            detail = f"Error: The configured AI model '{CHAT_MODEL}' was not found or is not available for this API key. Full error: {error_msg}"
        else:
            detail = f"AI Server Error: {error_msg}"

        raise HTTPException(status_code=500, detail=detail)


@app.post("/api/v1/analytics/generate")
async def generate_academic_report(request: AnalyticsReportRequest):
    try:
        ensure_ai_ready()
        
        # Determine which model to use
        target_model = request.model if request.model else CHAT_MODEL
        
        # If it's the same as default, use the pre-instantiated llm
        if target_model == CHAT_MODEL and llm:
            active_llm = llm
        else:
            # Instantiate a one-off LLM for this request
            active_llm = ChatGoogleGenerativeAI(
                model=target_model,
                google_api_key=ACTIVE_API_KEY,
                convert_system_message_to_human=True,
            )
        
        prompt = f"""{request.system_prompt}
        
        STRUCTURED SCHOOL DATA (JSON):
        {json.dumps(request.data, ensure_ascii=False, indent=2)}
        
        Generate the report now in Markdown format:"""
        
        response = active_llm.invoke(prompt)
        content = response.content
        
        # Handle cases where content might be a list of parts (multi-modal or multi-part response)
        if isinstance(content, list):
            # Join parts if they are strings or extract text from dicts
            content = "".join([part if isinstance(part, str) else str(part) for part in content])
            
        return {"report_markdown": content.strip() if hasattr(content, 'strip') else str(content)}
    except Exception as e:
        print(f"--- ANALYTICS REPORT ERROR ---: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/generate-report/")
async def generate_generic_report(request: PromptRequest):
    try:
        ensure_ai_ready()
        target_model = request.model if request.model else CHAT_MODEL
        
        if target_model == CHAT_MODEL and llm:
            active_llm = llm
        else:
            active_llm = ChatGoogleGenerativeAI(
                model=target_model,
                google_api_key=ACTIVE_API_KEY,
                convert_system_message_to_human=True,
            )
        
        response = active_llm.invoke(request.prompt)
        content = response.content
        
        if isinstance(content, list):
            content = "".join([part if isinstance(part, str) else str(part) for part in content])
            
        return {"report_markdown": content.strip() if hasattr(content, 'strip') else str(content)}
    except Exception as e:
        print(f"--- GENERIC REPORT ERROR ---: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/chat/")
async def chat_with_tutor(request: ChatRequest):
    try:
        ensure_ai_ready()

        if request.session_id not in session_histories:
            session_histories[request.session_id] = ChatMessageHistory()

        history = session_histories[request.session_id]

        past_messages = history.messages[-6:] if len(history.messages) > 6 else history.messages
        chat_history_str = ""
        for message in past_messages:
            role = "User" if isinstance(message, HumanMessage) else "AI"
            chat_history_str += f"{role}: {message.content}\n"

        docs = []
        try:
            docs = vector_store_manager.search_similar(request.message, k=3)
        except Exception as e:
            print(f"Vector Search Warning: {e}")

        context = "\n\n".join([doc.page_content for doc in docs])
        if not context.strip():
            context = "No specific source material found for this query. Use your general knowledge but mention you are answering without specific course context."

        prompt = f"""You are 'EduLearn AI Tutor', a premium educational assistant.
        Follow the school curriculum and be encouraging.

        CONTEXT FROM COURSE MATERIALS:
        {context}

        RECENT CONVERSATION:
        {chat_history_str}

        USER QUESTION: {request.message}

        ANSWER (in Arabic):"""

        response = llm.invoke(prompt)
        ai_reply = response.content

        history.add_user_message(request.message)
        history.add_ai_message(ai_reply)

        return {
            "reply": ai_reply,
            "session_id": request.session_id,
            "sources": [doc.metadata.get("source", "Unknown") for doc in docs],
        }
    except Exception as e:
        error_msg = str(e)
        print(f"Chat Error: {error_msg}")

        if "403" in error_msg or "leaked" in error_msg.lower():
            detail = "Critical: The configured Gemini API key has been revoked or reported as leaked. Generate a new key in Google AI Studio and update GEMINI_API_KEY."
        elif "404" in error_msg or "not found" in error_msg.lower():
            detail = f"Error: The configured AI model '{CHAT_MODEL}' was not found or is not available for this API key."
        else:
            detail = f"AI Server Error: {error_msg}"

        raise HTTPException(status_code=500, detail=detail)


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)
