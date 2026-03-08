from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel
import uvicorn
import os
import shutil
from dotenv import load_dotenv
from document_processor import DocumentProcessor
from vector_store import VectorStoreManager
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.prompts import PromptTemplate
load_dotenv()

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
llm = ChatGoogleGenerativeAI(model="gemini-1.5-pro", convert_system_message_to_human=True)

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

@app.post("/upload-pdf/")
async def upload_pdf(file: UploadFile = File(...)):
    if not file.filename.endswith('.pdf'):
        raise HTTPException(status_code=400, detail="Only PDF files are supported.")
    
    file_path = os.path.join(UPLOAD_DIR, file.filename)
    
    # Save the uploaded file temporarily
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    try:
        # Process the PDF to get chunks
        chunks = processor.process_pdf(file_path)
        
        if chunks:
            # Store in Vector DB
            vector_store_manager.add_texts(chunks, metadata={"source": file.filename})
        
        # Clean up the file after processing
        os.remove(file_path)
        
        return {
            "message": "File processed and added to knowledge base successfully",
            "filename": file.filename,
            "total_chunks_added": len(chunks)
        }
    except Exception as e:
        # Ensure cleanup on error
        if os.path.exists(file_path):
            os.remove(file_path)
        raise HTTPException(status_code=500, detail=f"Error processing document: {str(e)}")

@app.post("/chat/")
async def chat_with_tutor(request: ChatRequest):
    try:
        # Search for relevant context
        docs = vector_store_manager.search_similar(request.message, k=3)
        context = "\n\n".join([doc.page_content for doc in docs])
        
        if not context.strip():
            return {"reply": "I don't have any course material loaded to answer your question yet."}

        # Generate response
        prompt = prompt_template.format(context=context, question=request.message)
        response = llm.invoke(prompt)
        
        return {
            "reply": response.content,
            "sources": [doc.metadata.get("source", "Unknown") for doc in docs]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error chatting with tutor: {str(e)}")

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)
