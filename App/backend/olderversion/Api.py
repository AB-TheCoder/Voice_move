# this is basic api for the app which will be used to send the image to the backend and get the output.
import fastapi as api 
import cv2
import numpy as np
from App.Source import OCR
app=api.FastAPI()

@app.post("/enhance_image")
def enhance_image(image: np.ndarray):
    return OCR.enhance_for_ocr(image)


