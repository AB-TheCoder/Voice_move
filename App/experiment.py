
import numpy as np



from paddleocr import PaddleOCR
image_path=r"App\Data\temporary_data.png"
ocr = PaddleOCR(use_doc_orientation_classify=False, 
    use_doc_unwarping=False, 
    use_textline_orientation=False,lang='en'
    )
result=ocr.ocr(image_path)
# def text_detection(image_path:str,image_bgr:np.ndarray) -> np.ndarray:
#     engine=ocr.TextDetection()
#     result=engine.predict(image_path if image_bgr is None else image_bgr)
#     return result


# print(text_detection(r"App\Data\temporary_data.png",None))