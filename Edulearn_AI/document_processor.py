import fitz  # PyMuPDF
from langchain_text_splitters import RecursiveCharacterTextSplitter
import os

class DocumentProcessor:
    def __init__(self, chunk_size=1000, chunk_overlap=200):
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=chunk_size,
            chunk_overlap=chunk_overlap,
            separators=["\n\n", "\n", " ", ""]
        )

    def extract_text_from_pdf(self, file_path: str) -> str:
        """
        Extracts all text from a given PDF file.
        """
        text = ""
        try:
            doc = fitz.open(file_path)
            for page in doc:
                text += page.get_text()
            return text
        except Exception as e:
            print(f"Error reading PDF {file_path}: {e}")
            raise e

    def process_pdf(self, file_path: str) -> list[str]:
        """
        Extracts text from a PDF and splits it into manageable chunks.
        """
        full_text = self.extract_text_from_pdf(file_path)
        if not full_text.strip():
            return []
        
        chunks = self.text_splitter.split_text(full_text)
        return chunks

# Example Usage (for testing locally later)
if __name__ == "__main__":
    # Create a dummy pdf for testing if needed or test with real one
    pass
