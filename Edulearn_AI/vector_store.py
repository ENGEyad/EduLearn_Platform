import os
from langchain_community.vectorstores import FAISS
from langchain_google_genai import GoogleGenerativeAIEmbeddings
from langchain_core.documents import Document

class VectorStoreManager:
    def __init__(self, persist_directory="vector_db", api_key=None):
        self.persist_directory = persist_directory
        active_api_key = api_key or os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY")
        self.embeddings = None
        if active_api_key:
            self.embeddings = GoogleGenerativeAIEmbeddings(
                model="models/embedding-001",
                google_api_key=active_api_key
            )
        self.vector_store = None
        self._load_or_create_db()

    def _load_or_create_db(self):
        if self.embeddings is None:
            return
        if os.path.exists(self.persist_directory):
            try:
                self.vector_store = FAISS.load_local(
                    self.persist_directory, 
                    self.embeddings,
                    allow_dangerous_deserialization=True # Required for local FAISS loading
                )
                print("Loaded existing vector database.")
            except Exception as e:
                print(f"Failed to load vector database: {e}. Creating new one.")
                self.vector_store = None

    def add_texts(self, texts: list[str], metadata: dict = None):
        if self.embeddings is None:
            raise RuntimeError("Gemini embeddings are unavailable because no API key is configured.")
        documents = [Document(page_content=t, metadata=metadata or {}) for t in texts]
        
        if self.vector_store is None:
            self.vector_store = FAISS.from_documents(documents, self.embeddings)
        else:
            self.vector_store.add_documents(documents)
            
        self.vector_store.save_local(self.persist_directory)
        print(f"Saved {len(texts)} chunks to vector database.")

    def search_similar(self, query: str, k: int = 4) -> list[Document]:
        if self.embeddings is None or self.vector_store is None:
            return []
        return self.vector_store.similarity_search(query, k=k)
