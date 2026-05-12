import numpy as np

try:
    from paddleocr import PaddleOCR,PaddleOCRVL
    import cv2
    image_path = r'App\Data\temporary_data.png'
    ocr = PaddleOCR(use_textline_orientation=True,lang='en')
    image=cv2.imread(image_path)

    output = ocr.predict(input=image)

    print(output)

except Exception as e :
    print(e)


# import cv2 as cv2

# image_path1= r'App\Data\temporary_data.png'
# image_path2= r'App\Data\temporary_data2.png'
# image_path3 = r'App\Data\score-sheet-showing-notations-of-a-chess-game-2WREGAE.jpg'
# img = cv2.imread(image_path1)
# img2 = cv2.imread(image_path2)
# img3 = cv2.imread(image_path3)
# print(type(img))
# print(img.shape)
# print(img.dtype)
