"""
OCR helper that enhances an image and extracts text with PaddleOCR.

Notes:
- PaddleOCR is heavy to import/initialize; this module caches the OCR engine.
- PaddleOCR expects either an image path or an ndarray (H, W, C) image.
"""

from argparse import ArgumentError
from csv import Error
from sqlite3 import DataError
import cv2# open cv
import numpy as np
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple
import sys

try:
    from paddleocr import PaddleOCR          # error handling for module presence and proper functioning
except ModuleNotFoundError as e:  # pragma: no cover
    PaddleOCR = None  # type: ignore[assignment]
    _PADDLEOCR_IMPORT_ERROR = e
else:
    _PADDLEOCR_IMPORT_ERROR = None    


class OCR():
    '''
    used to extract text from images and convert into proper clean formats .
    performs all levels of ocr pipeline.
    uses paddleocr for image manipulation and chess to maintain chess logic and structure in the output.
    '''
    def __init__(
        self,
        image_path: str,
        lang: str = "en",
        use_textline:bool=True

    ) -> None:
        self.image_path = image_path
        self.image_bgr = cv2.imread(self.image_path) # the images data in np.ndarray form
        if self.image_bgr is None:#raised when there is an error when the module reads the image
            raise ValueError(f"Could not read image at path: {self.image_path}")
        self.enhanced_image_path: Optional[str] = None
        self.enhanced_imagebgr: Optional[np.ndarray] = None
#image>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        self.only_detection :Optional[bool] = False    # arguements for paddleocr
        self.lang:Optional[str] = lang
        self.use_textline = use_textline
        

    @property
    def ocr_model(self): # to create the ocr model . 
        try:
            
            ocr_model=PaddleOCR(
                use_textline_orientation=self.use_textline,
                lang=self.lang
            )
            return ocr_model   
        except (ArgumentError , ModuleNotFoundError) as error:
            print('there is some problem with the Paddleocr Model or the arguement')

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

            # 2) upscale for OCR    #NOTE:the dimensions of the image should not be greater than 2000/2000 otherwise the ocr will crash will detecting it. 
            h, w = gray.shape[:2]
            scale = 2
            gray = cv2.resize(gray, (w * scale, h * scale), interpolation=cv2.INTER_CUBIC)
            h,w = gray.shape[:2]
                # Maximum allowed size
            MAX_SIZE = 2000
            if h >MAX_SIZE or w>MAX_SIZE:

                # Calculate scaling factor
                scale = min(MAX_SIZE / w, MAX_SIZE / h)
                new_w = int(w * scale)
                new_h = int(h * scale)
                gray = cv2.resize(gray, (new_w, new_h), interpolation=cv2.INTER_CUBIC)
                # New dimensions
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
            raise RuntimeError(f"Failed to enhance image for OCR: {e}") from e
    
    def text_Recognition(self, image_bgr: Optional[np.ndarray] = None) -> list:
        try:
            if image_bgr is None:
                image_bgr = self.image_bgr
            if image_bgr is None or (
                isinstance(image_bgr, np.ndarray) and image_bgr.size == 0
            ):
                raise DataError("the provided data is nul")
            model = self.ocr_model
            output = model.predict(input = image_bgr)
            self.Ocr_output=output
            return output
        except Exception as error:
            raise RuntimeError(f"the ocr could not recognise text because \"{error}\"")

    
    def extract_reqDATA(self,predict_result:Optional=None, min_confidence:Optional[float]=0.0):
        """
        Works with PaddleOCR 3.4 predict() output:
        [
        {
            ...,
            "rec_texts": [...],
            "rec_scores": [...]
        }
        ]
        It returns a clean formated result of the output given by the OCR.
        """
        try:
            clean = []

            if not predict_result:# if the arguements are not appropriate.this conditions scoops it out.
                raise ArgumentError("the given output is NUL or not appropraite")
                return clean

            for page in predict_result:# the output is present in standered nested structure.
                                       # this series of loops scoops out the required data and then
                                       #presents them in simple and workable data format.
                if not isinstance(page, dict):
                    raise DataError("The data is not present in required form,i.e,in list and dictionarys nested structure")
                    continue

                texts = page.get("rec_texts", [])
                scores = page.get("rec_scores", [])

                for text, score in zip(texts, scores):
                    text = str(text).strip()
                    score = float(score)

                    if text and score >= min_confidence:# to remove any text which the model has confidence <min_confidence
                        clean.append({
                            "text": text,
                            "accuracy": round(score, 4)
                        })
        except Exception as error:
            raise RuntimeError(f"The function could not provide and output because{error}")
        finally:
            self.processed_output = clean
            return clean 
        

if __name__ == "__main__":
    model = OCR(r'App\Data\temporary_data.png',lang ='en')
    model.text_Recognition(model.image_bgr)
    print(model.extract_reqDATA(model.Ocr_output))
    
    

    
