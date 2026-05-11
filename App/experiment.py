




from paddleocr import TextRecognition
image_path=r"App\Data\temporary_data.png"


model = TextRecognition()
output = model.predict(input=image_path)

print(output)
    
# def text_detection(image_path:str,image_bgr:np.ndarray) -> np.ndarray:
#     engine=ocr.TextDetection()
#     result=engine.predict(image_path if image_bgr is None else image_bgr)
#     return result


# print(text_detection(r"App\Data\temporary_data.png",None))