"""
OCR helper that enhances an image and extracts text with PaddleOCR.

Notes:
- PaddleOCR is heavy to import/initialize; this module caches the OCR engine.
- PaddleOCR expects either an image path or an ndarray (H, W, C) image.
"""

import cv2
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
        

        
    ) -> None:
        self.image_path = image_path
        self.lang = lang
        self.image_bgr = cv2.imread(self.image_path)
        if self.image_bgr is None:
            raise ValueError(f"Could not read image at path: {self.image_path}")

        self.enhanced_image_path: Optional[str] = None
        self.enhanced_imagebgr: Optional[np.ndarray] = None
        self._paddleocr: Optional[Any] = None
        
    
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
            raise RuntimeError(f"Failed to enhance image for OCR: {e}") from e

    def _get_paddleocr(self) -> Any:
        if _PADDLEOCR_IMPORT_ERROR is not None or PaddleOCR is None:
            raise ModuleNotFoundError(
                "paddleocr is not installed in the current Python environment. "
                "Install it with: `pip install paddleocr` (and ensure PaddlePaddle is installed)."
            ) from _PADDLEOCR_IMPORT_ERROR
        if self._paddleocr is None:
            try:
                self._paddleocr = PaddleOCR(use_angle_cls=True, lang=self.lang)
            except RuntimeError as e:
                msg = str(e)
                if "paddlepaddle" in msg.lower() and "not installed" in msg.lower():
                    raise RuntimeError(
                        "PaddleOCR is installed, but PaddlePaddle (`paddlepaddle`) is missing. "
                        "Install a supported PaddlePaddle build, e.g. `pip install paddlepaddle`.\n"
                        f"Current Python: {sys.version.split()[0]}. If install fails, use Python 3.10/3.11 "
                        "in a fresh venv, then reinstall `paddleocr`."
                    ) from e
                raise
        return self._paddleocr

    def detect_text_paddleocr(
        self,
        image_bgr: Optional[np.ndarray] = None,
        image_path: Optional[str] = None,
        *,
        detection_only: bool = False,
    ) -> List[Any]:
        """
        Detect (and optionally recognize) text using PaddleOCR.

        - If `detection_only=True`, returns detection boxes without recognition.
        - Provide either `image_bgr` or `image_path`. If neither is provided,
          it uses the enhanced image (if available) else the original image path.
        """
        ocr_engine = self._get_paddleocr()

        if image_bgr is None and image_path is None:
            if self.enhanced_image_path is not None:
                image_path = self.enhanced_image_path
            else:
                image_path = self.image_path

        if image_bgr is not None and image_path is not None:
            raise ValueError("Provide only one of `image_bgr` or `image_path`.")

        # PaddleOCR accepts either an ndarray (BGR/RGB both typically work) or a filesystem path.
        result = ocr_engine.predict(image_bgr if image_bgr is not None else image_path)
          # type: ignore[arg-type]
        return result

    # Backwards-compatible alias (keeps your existing call sites working)
    def text_dectection(self) -> List[Any]:
        return self.detect_text_paddleocr(detection_only=True)
    def text_recognition(self):
        """this is the function for recognising text form images."""
        try:
            # Full OCR (detection + recognition)
            return self.detect_text_paddleocr(detection_only=False)
        except Exception as e:
            raise RuntimeError(f"Text recognition failed: {e}") from e
if __name__ == "__main__":
    model=OCR(r'App\Data\score-sheet-showing-notations-of-a-chess-game-2WREGAE.jpg','en',)
    model.enhance_for_ocr(model.image_bgr)
    # print(model.text_dectection())
    print(model.text_dectection())

    
