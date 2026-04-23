# This is the main source code file for the app-(name not finalised)
import google.generativeai as gemini
import os

# Configure with your API key
gemini.configure(api_key=)

# Initialize the model
model = gemini.GenerativeModel('gemini-2.5-flash')

# Generate text
question=input('What do You Want To Ask: ')
response = model.generate_content(question)
print('Ans\n',response.text)
