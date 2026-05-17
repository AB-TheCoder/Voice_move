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


def extract_reqDATA(
    self,
    predict_result: Optional[list] = None,
    min_confidence: float = 0.0,
    get_pos: bool = False,
) -> list:
    """
    Works with PaddleOCR 3.4 predict() output:
    [
        {
            "rec_texts": [...],
            "rec_scores": [...],
            "rec_polys": [...],   # optional, for positions
        }
    ]
    Returns list of {"text", "accuracy"} or adds "pos" (top-left) when get_pos=True.
    """
    clean: list = []

    if not predict_result:
        raise ValueError("predict_result is empty or None")

    try:
        for page in predict_result:
            if not isinstance(page, dict):
                raise ValueError(
                    "Each page must be a dict with rec_texts / rec_scores"
                )

            texts = page.get("rec_texts", [])
            scores = page.get("rec_scores", [])
            polys = page.get("rec_polys", [])

            if len(texts) != len(scores):
                raise ValueError(
                    f"rec_texts ({len(texts)}) and rec_scores ({len(scores)}) length mismatch"
                )
            if get_pos and len(texts) != len(polys):
                raise ValueError(
                    f"rec_polys ({len(polys)}) length mismatch with rec_texts ({len(texts)})"
                )

            if get_pos:
                rows = zip(texts, scores, polys)
            else:
                rows = zip(texts, scores)

            for row in rows:
                text = str(row[0]).strip()
                score = float(row[1])

                if not text or score < min_confidence:
                    continue

                item = {
                    "text": text,
                    "accuracy": round(score, 4),
                }

                if get_pos:
                    poly = np.asarray(row[2])
                    # top-left corner for sorting (y then x)
                    top_left = poly.min(axis=0)
                    item["pos"] = [int(top_left[0]), int(top_left[1])]

                clean.append(item)

    except ValueError:
        raise
    except Exception as error:
        raise RuntimeError(
            f"The function could not provide an output because {error}"
        ) from error

    self.processed_output = clean
    return clean