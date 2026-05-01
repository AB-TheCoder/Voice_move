# this file contains the code for clicking pictures and enchancing them before sending them to the llm ai for analyis.
import cv2
import numpy as np

class OCR():
    def __init__(self,image_path:str) -> None:
        self.image_path=image_path
        self.image_bgr=cv2.imread(self.image_path)
    
    def enhance_for_ocr(self,image_bgr: np.ndarray) -> np.ndarray:
        try:
            # 1) grayscale
            gray = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2GRAY)

            # 2) upscale for OCR
            h, w = gray.shape[:2]
            scale = 2
            gray = cv2.resize(gray, (w * scale, h * scale), interpolation=cv2.INTER_CUBIC)

            # 3) denoise (keeps edges)
            gray = cv2.bilateralFilter(gray,9, 75, 75)

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
            self.enhanced_image_binary = cv2.morphologyEx(binary, cv2.MORPH_OPEN, kernel2, iterations=1)

            
            cv2.imwrite(r'App\Data\temporary_data.png',self.enhanced_image_binary)
            return self.enhanced_image_binary
        except Exception as e:
            print(e)
        
        