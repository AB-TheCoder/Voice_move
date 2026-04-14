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

    model="gemini-2.5-flash",
    contents='pass'
    
)
print(model.text)


#----------------------------------------------------------------------------------------------------------------------------
#image Capturing/uploading
# capturing
import cv2 as cv
class picture():
    def click(self):
        pass
    def upload(self):
        pass


#-----------------------------------------------------------------------------------------------------------------------------
# Timer
import time 
class clock():# to create different clocks
    def __init__(self,Time=None,increament=None):
        self.time=Time
        self.increment=increament
        clock=time.Clo
    
    def tick(self):
        pass
    def stop(self):
        pass
    

def create_timer():
    Time=input('Time control')
    Increment=input('Increament')
    clock1=clock(Time,Increment)
    clock2=clock(Time,Increment)













#------------------------------------------------------------------------------------------------------------------------
# Stock Fish Analyis----















#---------------------------------------------------------------------------------------------------------------------
