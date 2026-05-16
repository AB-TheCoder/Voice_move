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
import os
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
        use_textline: bool = True,
        enhance_mode: str = "handwriting",
    ) -> None:
        self.image_path = image_path
        self.image_bgr = cv2.imread(self.image_path) # the images data in np.ndarray form
        if self.image_bgr is None:#raised when there is an error when the module reads the image
            raise ValueError(f"Could not read image at path: {self.image_path}")
        self.enhanced_image_path: Optional[str] = None
        self.enhanced_imagebgr: Optional[np.ndarray] = None
        if enhance_mode not in ("handwriting", "printed"):
            raise ValueError("enhance_mode must be 'handwriting' or 'printed'")
        self.enhance_mode = enhance_mode
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

    @staticmethod
    def _to_grayscale(image_bgr: np.ndarray) -> np.ndarray:
        if len(image_bgr.shape) == 2:
            return image_bgr
        if image_bgr.shape[2] == 1:
            return image_bgr[:, :, 0]
        return cv2.cvtColor(image_bgr, cv2.COLOR_BGR2GRAY)

    @staticmethod
    def _resize_for_ocr(gray: np.ndarray, upscale: float, max_size: int = 2000) -> np.ndarray:
        # NOTE: keep both sides <= max_size or PaddleOCR may crash on very large images
        h, w = gray.shape[:2]
        gray = cv2.resize(
            gray,
            (int(w * upscale), int(h * upscale)),
            interpolation=cv2.INTER_CUBIC,
        )
        h, w = gray.shape[:2]
        if max(h, w) > max_size:
            downscale = min(max_size / w, max_size / h)
            gray = cv2.resize(
                gray,
                (int(w * downscale), int(h * downscale)),
                interpolation=cv2.INTER_CUBIC,
            )
        return gray

    def _enhance_handwriting(self, gray: np.ndarray) -> np.ndarray:
        gray = self._resize_for_ocr(gray, upscale=2.5)
        gray = cv2.fastNlMeansDenoising(gray, None, h=8, templateWindowSize=7, searchWindowSize=21)

        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        gray = clahe.apply(gray)

        bg = cv2.GaussianBlur(gray, (0, 0), sigmaX=25, sigmaY=25)
        gray = cv2.divide(gray, bg, scale=255)

        blur = cv2.GaussianBlur(gray, (0, 0), sigmaX=1.0)
        gray = cv2.addWeighted(gray, 1.4, blur, -0.4, 0)

        return cv2.cvtColor(gray, cv2.COLOR_GRAY2BGR)

    def _enhance_printed(self, gray: np.ndarray) -> np.ndarray:
        gray = self._resize_for_ocr(gray, upscale=2.0)
        gray = cv2.bilateralFilter(gray, 9, 75, 75)

        clahe = cv2.createCLAHE(clipLimit=2.5, tileGridSize=(8, 8))
        gray = clahe.apply(gray)

        kernel = np.array([[0, -1, 0], [-1, 5, -1], [0, -1, 0]])
        gray = cv2.filter2D(gray, -1, kernel)

        binary = cv2.adaptiveThreshold(
            gray, 255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY,
            31, 10,
        )
        kernel2 = cv2.getStructuringElement(cv2.MORPH_RECT, (2, 2))
        return cv2.morphologyEx(binary, cv2.MORPH_OPEN, kernel2, iterations=1)

    def _persist_enhanced(self, enhanced: np.ndarray) -> np.ndarray:
        temp_path = Path(__file__).resolve().parent / "temp_data" / "temporary_data.png"
        temp_path.parent.mkdir(parents=True, exist_ok=True)
        cv2.imwrite(str(temp_path), enhanced)
        self.enhanced_image_path = str(temp_path)
        self.enhanced_imagebgr = enhanced
        self.image_bgr = cv2.imread(str(temp_path))
        return self.enhanced_imagebgr

    def enhance_for_ocr(
        self,
        image_bgr: np.ndarray,
        mode: Optional[str] = None,
    ) -> np.ndarray:
        """Enhance image before OCR.

        mode 'handwriting': grayscale pipeline for thin strokes (score sheets).
        mode 'printed': binarize + morphology for typed text.
        Uses self.enhance_mode when mode is omitted.
        """
        try:
            mode = mode or self.enhance_mode
            if mode not in ("handwriting", "printed"):
                raise ValueError("mode must be 'handwriting' or 'printed'")

            gray = self._to_grayscale(image_bgr)
            if mode == "handwriting":
                enhanced = self._enhance_handwriting(gray)
            else:
                enhanced = self._enhance_printed(gray)
            return self._persist_enhanced(enhanced)
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
    
    def remove_tempDATA(self) -> None:
        try:
            if os.path.exists(self.enhanced_image_path):
                os.remove(self.enhanced_image_path)
        except Exception as error:
            raise RuntimeError(f"temperory files could not be removed because: {error}")

if __name__ == "__main__":
    model = OCR(r'App\Data\ti7.jpeg', lang='en', enhance_mode='handwriting')
    model.enhance_for_ocr(model.image_bgr)  # mode='printed' to use the old pipeline
    model.text_Recognition(model.image_bgr)
    print(model.extract_reqDATA(model.Ocr_output))
    # model.remove_tempDATA()
    
    

    
