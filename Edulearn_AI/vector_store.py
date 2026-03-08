import os
from langchain_community.vectorstores import FAISS
from langchain_google_genai import GoogleGenerativeAIEmbeddings
from langchain_core.documents import Document

class VectorStoreManager:
    def __init__(self, persist_directory="vector_db"):
        self.persist_directory = persist_directory
        self.embeddings = GoogleGenerativeAIEmbeddings(model="models/embedding-001")
        self.vector_store = None
        self._load_or_create_db()

    def _load_or_create_db(self):
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
        documents = [Document(page_content=t, metadata=metadata or {}) for t in texts]
        
        if self.vector_store is None:
            self.vector_store = FAISS.from_documents(documents, self.embeddings)
        else:
            self.vector_store.add_documents(documents)
            
        self.vector_store.save_local(self.persist_directory)
        print(f"Saved {len(texts)} chunks to vector database.")

    def search_similar(self, query: str, k: int = 4) -> list[Document]:
        if self.vector_store is None:
            return []
        return self.vector_store.similarity_search(query, k=k)
