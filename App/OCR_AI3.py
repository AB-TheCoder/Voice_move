"""
OCR helper that enhances an image and extracts text with PaddleOCR.

Notes:
- PaddleOCR is heavy to import/initialize; this module caches the OCR engine.
- PaddleOCR expects either an image path or an ndarray (H, W, C) image.
"""

from argparse import ArgumentError
import cv2# open cv
import numpy as np
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple
import sys

try:
    from paddleocr import PaddleOCR
except ModuleNotFoundError as e:  # pragma: no cover
    PaddleOCR = None  # type: ignore[assignment]
    _PADDLEOCR_IMPORT_ERROR = e
else:
    _PADDLEOCR_IMPORT_ERROR = None


class OCR():
    def __init__(
        self,
        image_path: str,
        lang: str = "en",
        use_textline:bool=True

    ) -> None:
        self.image_path = image_path
        self.image_bgr = cv2.imread(self.image_path)
        if self.image_bgr is None:
            raise ValueError(f"Could not read image at path: {self.image_path}")
        self.enhanced_image_path: Optional[str] = None
        self.enhanced_imagebgr: Optional[np.ndarray] = None
#image>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        self.only_detection :Optional[bool] = False
        self.lang:Optional[str] = 'en'
        self.use_textline = use_textline
        
        try:
            self.ocr_model=PaddleOCR(
                use_textline_orientation=use_textline,
                lang=lang,
                
            )
        except (ArgumentError , ModuleNotFoundError) as error:
            print('there is some problem with the Paddleocr Model or the arguement')

    @property
    def _getOCR(self):
        try:
            if self.only_detection==True:pass
            self.ocr_model=PaddleOCR(
                use_textline_orientation=self.use_textline,
                lang=self.lang
            )
            return self.ocr_model   
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
    def Text_detection(self,Image_bgr:np.ndarray=None)->list:
        """
        This is the function for detecting the text present in the image
        prior to the recognition part.
        Not all text are required hence required customization will be done while detection*NOTFINAL*
        """
        try:
            if (Image_bgr==None):
                Image_bgr==self.enhanced_imagebgr
        except ValueError as v:
            print("The provided data is inappropraite")
        try:
            self.only_detection = True

        except:
            pass

if __name__ == "__main__":
    pass
    

    
