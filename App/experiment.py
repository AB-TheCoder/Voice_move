
import numpy as np

try:
    from paddleocr import PaddleOCR,PaddleOCRVL
    import cv2
    image_path = r'App\Data\score-sheet-showing-notations-of-a-chess-game-2WREGAE.jpg'
    ocr = PaddleOCR(use_textline_orientation=True,lang='en')
    image=cv2.imread(image_path)

    output = ocr.predict(input=image)

    for res in output:
        print(f"Text: {res[0]}, Confidence: {res[1]:.4f}")
except Exception as e :
    print(e)
