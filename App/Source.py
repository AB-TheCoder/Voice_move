# This is the main source code file for the app-(name not finalised)


# packages and modules
import google.genai as genai
import os




# gemini (image recognistion)


def analyis_image():
    pass
# Configure with your API key
gemini=genai.Client(api_key="AIzaSyA_ENCdLto3XHB3fLHTGKF51DsjpSdBFuw")

# Initialize the model

model=gemini.models.generate_content(

    model="gemini-2.5-pro",
    contents='generate me a image of a elephant'
)
print(model.text)


#----------------------------------------------------------------------------------------------------------------------------
#image Capturing/uploading
# capturing


#-----------------------------------------------------------------------------------------------------------------------------
# Timer
import timer as ti
class clock():# to create different clocks
    def __init__(self,time,increament):
        pass














#------------------------------------------------------------------------------------------------------------------------
# Stock Fish Analyis----















#---------------------------------------------------------------------------------------------------------------------
