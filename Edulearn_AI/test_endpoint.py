import requests
import json

url = "http://127.0.0.1:8001/api/v1/analytics/generate"
payload = {
    "system_prompt": "You are an assistant. Say hello.",
    "data": {"test": "data"},
    "model": "gemini-flash-latest"
}

try:
    response = requests.post(url, json=payload)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.text}")
except Exception as e:
    print(f"Error: {e}")
