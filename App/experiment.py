from argparse import ArgumentError
from sqlite3 import DataError
import numpy as np

try:
    from paddleocr import PaddleOCR
    import cv2
    image_path = r'App\Data\ti5.jpeg'
    ocr = PaddleOCR(use_textline_orientation=True,lang=None)
    image=cv2.imread(image_path)


    def extract_text_and_accuracy(predict_result, min_confidence=0.0):
        """
        Works with PaddleOCR 3.4 predict() output:
        [
        {
            ...,
            "rec_texts": [...],
            "rec_scores": [...]
        }
        ]
        """
        clean = []

        if not predict_result:
            raise ArgumentError('the given output is NUL')
            return clean

        for page in predict_result:
            if not isinstance(page, dict):
                raise DataError("The data is not present in required form,i.e,in list and dictionarys nested structure")
                continue

            texts = page.get("rec_texts", [])
            scores = page.get("rec_scores", [])

            for text, score in zip(texts, scores):
                text = str(text).strip()
                score = float(score)

                if text and score >= min_confidence:
                    clean.append({
                        "text": text,
                        "accuracy": round(score, 4)
                    })

        return clean 

    output = ocr.predict(input=image,return_word_box=False)
    

    only_t_A=extract_text_and_accuracy(output)
    print(only_t_A)

except Exception as e :
    print(e)