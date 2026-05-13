import os
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

key = os.getenv("GEMINI_API_KEY")
print(f"Testing key: {key[:4]}...{key[-4:]}")

genai.configure(api_key=key)
model = genai.GenerativeModel('gemini-pro')

try:
    response = model.generate_content("Say hello in Arabic")
    print(f"Success! Response: {response.text}")
except Exception as e:
    print(f"Failure! Error: {e}")
