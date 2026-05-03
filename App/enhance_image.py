# this file contains the code for clicking pictures and enchancing them before sending them to the llm ai for analyis.
import cv2
import numpy as np
from paddleocr import PaddleOCR


class OCR:
    """PaddleOCR-based text detection and recognition on board / document images."""

    def __init__(
        self,
        image_path: str,
        *,
        lang: str = "en",
        use_gpu: bool = False,
        show_log: bool = False,
    ) -> None:
        self.image_path = image_path
        self.image_bgr = cv2.imread(self.image_path)
        self._paddle = PaddleOCR(
            use_angle_cls=True,
            lang=lang,
            use_gpu=use_gpu,
            show_log=show_log,
        )

    def Preprocessing(self, image_bgr: np.ndarray) -> np.ndarray:
        """Improve image quality before OCR (optional; PaddleOCR also handles raw RGB/BGR)."""
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

        # 5) sharpening (helps blurred text)
        kernel = np.array([[0, -1, 0], [-1, 5, -1], [0, -1, 0]])
        gray = cv2.filter2D(gray, -1, kernel)

        # 6) adaptive threshold (better than OTSU for uneven lighting)
        binary = cv2.adaptiveThreshold(
            gray,
            255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY,
            31,
            10,
        )

        # 7) morphology cleanup — remove tiny noise
        kernel2 = cv2.getStructuringElement(cv2.MORPH_RECT, (2, 2))
        self.enhanced_imagebgr = cv2.morphologyEx(
            binary, cv2.MORPH_OPEN, kernel2, iterations=1
        )

        cv2.imwrite(r"App\Data\temporary_data.png", self.enhanced_imagebgr)
        return self.enhanced_imagebgr

    @staticmethod
    def _to_bgr_three_channel(image: np.ndarray) -> np.ndarray:
        """PaddleOCR expects color BGR ndarray for predict; convert single-channel if needed."""
        if image.ndim == 2:
            return cv2.cvtColor(image, cv2.COLOR_GRAY2BGR)
        return image

    def Text_Detection(
        self,
        image_bgr: Optional[np.ndarray] = None,
        *,
        use_preprocessed_binary: bool = False,
        cls: bool = True,
    ) -> List[Dict[str, Any]]:
        """Detect text regions and run recognition with PaddleOCR.

        Each item: ``{"box": [[x,y], ...], "text": str, "confidence": float}`` (polygon in image coords).

        Args:
            image_bgr: BGR image; defaults to ``self.image_bgr``.
            use_preprocessed_binary: If True and ``enhanced_imagebgr`` exists, use that ndarray.
            cls: Passed to PaddleOCR (use angle classifier for rotated text).
        """
        if image_bgr is None:
            if use_preprocessed_binary and getattr(self, "enhanced_imagebgr", None) is not None:
                image_bgr = self.enhanced_imagebgr
            else:
                image_bgr = self.image_bgr

        if image_bgr is None:
            return []

        inp = self._to_bgr_three_channel(image_bgr)
        raw = self._paddle.ocr(inp, cls=cls)

        out: List[dict[str, Any]] = []
        if not raw or raw[0] is None:
            return out

        for line in raw[0]:
            box, rec = line
            text, confidence = rec[0], float(rec[1])
            out.append({"box": box, "text": text, "confidence": confidence})
        return out

    def all_text_joined(self, **kwargs: Any) -> str:
        """Single string of recognized text lines in detection order (roughly top-to-bottom as returned)."""
        lines = self.Text_Detection(**kwargs)
        return "\n".join(item["text"] for item in lines)


