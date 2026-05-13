import numpy as np

try:
    from paddleocr import PaddleOCR,PaddleOCRVL
    import cv2
    image_path = r'App\Data\temporary_data.png'
    ocr = PaddleOCR(use_textline_orientation=True,lang='en')
    image=cv2.imread(image_path)


    def extract_text_and_accuracy(predict_result, min_conf=0.0):
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
            return clean

        for page in predict_result:
            if not isinstance(page, dict):
                continue

            texts = page.get("rec_texts", [])
            scores = page.get("rec_scores", [])

            for text, score in zip(texts, scores):
                text = str(text).strip()
                score = float(score)

                if text and score >= min_conf:
                    clean.append({
                        "text": text,
                        "accuracy": round(score, 4)
                    })

        return clean

    # def extract_text_and_accuracy(ocr_result):
    #     """
    #     Converts PaddleOCR output into:
    #     [{"text": "...", "accuracy": 0.98}, ...]
    #     """
    #     clean = []

    #     if not ocr_result:
    #         return clean

    #     # Typical PaddleOCR output (det=True, rec=True):
    #     # [
    #     #   [
    #     #     [box_points],
    #     #     ("recognized text", confidence_score)
    #     #   ],
    #     #   ...
    #     # ]
    #     for line_group in ocr_result:
    #         if not line_group:
    #             continue

    #         for item in line_group:
    #             # item is usually: [box, (text, score)]
    #             if (
    #                 isinstance(item, (list, tuple))
    #                 and len(item) >= 2
    #                 and isinstance(item[1], (list, tuple))
    #                 and len(item[1]) >= 2
    #             ):
    #                 text = str(item[1][0]).strip()
    #                 score = float(item[1][1])

    #                 if text:  # ignore empty text
    #                     clean.append({
    #                         "text": text,
    #                         "accuracy": round(score, 4)
    #                     })

    #     return clean
    output = ocr.predict(input=image)
    only_t_A=extract_text_and_accuracy(output)
    print(only_t_A)

except Exception as e :
    print(e)