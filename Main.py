# This is the main source code file for the app-(name not finalised)
import google.generativeai as genai
import os

# Configure with your API key
genai.configure(api_key="AIzaSyA_ENCdLto3XHB3fLHTGKF51DsjpSdBFuw")

# Initialize the model
model = genai.GenerativeModel('gemini-2.5-flash')

# Generate text
question=input('What do You Want To Ask: ')
response = model.generate_content(question)
print(response.text)
