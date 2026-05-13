import os
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

api_key = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY")
genai.configure(api_key=api_key)

model = genai.GenerativeModel('gemini-flash-latest')
try:
    response = model.generate_content("Say hello in Arabic")
    print(response.text)
except Exception as e:
    print(f"Error: {e}")
