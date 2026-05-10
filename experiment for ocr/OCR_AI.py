# this file contains the code for clicking pictures and enchancing them before sending them to the llm ai for analyis.
import sys
import cv2
import numpy as np
from pathlib import Path
from typing import Any, Dict, List, Optional
import pytesseract as tesai
tesai.pytesseract.tesseract_cmd = r"C:\Users\Aarav\AppData\Local\Programs\Tesseract-OCR\tesseract.exe"



class OCR():
    def __init__(
        self,
        image_path: str,
        
        
    ) -> None:
        self.image_path = image_path
        self.image_bgr = cv2.imread(self.image_path)
        if self.image_bgr is None:
            raise ValueError(f"Could not read image at path: {self.image_path}")

    
    def enhance_for_ocr(self,image_bgr: np.ndarray) -> np.ndarray:
        """ enhance the image for ocr .
        the image will be enhanced through a series of steps to improve the quality of the image.
        the image will be converted to grayscale, then upscaled, then denoised, then contrast boosted, then sharpened, then adaptive thresholded, then morphology cleaned.
        the image will be returned as a numpy array.
        the Better the input the cleaner the output.
        """
        try:
            # 1) grayscale
            gray = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2GRAY)

            # 2) upscale for OCR
            h, w = gray.shape[:2]
            scale = 2
            gray = cv2.resize(gray, (w * scale, h * scale), interpolation=cv2.INTER_CUBIC)

            # 3) denoise (keeps edges)
            gray = cv2.bilateralFilter(gray, 9, 75, 75)

            # 4) contrast boost (CLAHE)
            clahe = cv2.createCLAHE(clipLimit=2.5, tileGridSize=(8, 8))
            gray = clahe.apply(gray)

            # 5) sharpening (optional, helps blurred text)
            kernel = np.array([[0,-1,0],
                            [-1,5,-1],
                            [0,-1,0]])
            gray = cv2.filter2D(gray, -1, kernel)

            # 6) adaptive threshold (better than OTSU for uneven lighting)
            binary = cv2.adaptiveThreshold(
                gray, 255,
                cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                cv2.THRESH_BINARY,
                31, 10
            )

            # 7) morphology cleanup (optional)
            # Remove tiny noise and make text slightly more solid
            kernel2 = cv2.getStructuringElement(cv2.MORPH_RECT, (2, 2))
            self.enhanced_imagebgr = cv2.morphologyEx(binary, cv2.MORPH_OPEN, kernel2, iterations=1)

            
            temp_path = Path(__file__).resolve().parent / "Data" / "temporary_data.png"
            temp_path.parent.mkdir(parents=True, exist_ok=True)
            cv2.imwrite(str(temp_path), self.enhanced_imagebgr)
            self.image_bgr = cv2.imread(str(temp_path))
            self.enhanced_image_path = str(temp_path)
            return self.enhanced_imagebgr
        except Exception as e:
            print(e)# to be changed later to a proper error handling system.
    def text_dectection(self):
        """for personalization of the text which will be recognised i will carry out the detection pattern seperatly.
        """        
        try:
            boxes=tesai.image_to_data(self.enhanced_image_path)
            self.location_data=boxes
            return boxes
        except ValueError as error:
            print(error)
    def text_recognition(self):
        """this is the function for recognising text form images."""
        try:
            text=tesai.image_to_string(self.enhanced_image_path)
            self.recogTEXT=text
            return text
        except Exception as e:
            print(e)
if __name__ == "__main__":
    model=OCR(r'App\Data\score-sheet-showing-notations-of-a-chess-game-2WREGAE.jpg')
    model.enhance_for_ocr(model.image_bgr)
    # print(model.text_dectection())
    print(model.text_recognition())
    