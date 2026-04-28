"""
Read chess scoresheet images and convert them to clean PGN text.

Dependencies:
    pip install paddleocr python-chess opencv-python
"""

from __future__ import annotations

import argparse
import re
from typing import List, Sequence

import chess
import chess.pgn
import cv2
import numpy as np
from paddleocr import PaddleOCR


SAN_LIKE_PATTERN = re.compile(
    r"^(O-O-O|O-O|[KQRBN]?[a-h]?[1-8]?x?[a-h][1-8](=[QRBN])?[+#]?|[a-h]x?[a-h][1-8](=[QRBN])?[+#]?|[a-h][1-8])$"
)


class ScoreSheetReader:
    """OCR + chess-aware cleaning pipeline for handwritten/printed scoresheets."""

    def __init__(self, language: str = "en") -> None:
        self.ocr = PaddleOCR(use_angle_cls=True, lang=language)

    @staticmethod
    def _preprocess_image(image_path: str) -> np.ndarray:
        image = cv2.imread(image_path)
        if image is None:
            raise FileNotFoundError(f"Could not read image: {image_path}")

        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        filtered = cv2.bilateralFilter(gray, 9, 75, 75)
        _, binary = cv2.threshold(
            filtered, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU
        )
        return binary

    @staticmethod
    def _normalize_token(token: str) -> str:
        token = token.strip()
        token = token.replace("0-0-0", "O-O-O")
        token = token.replace("0-0", "O-O")
        token = token.replace("—", "-")
        token = token.replace("–", "-")
        token = token.replace("…", "")
        token = token.replace("?", "")
        token = token.replace("!", "")
        token = token.rstrip(".")
        return token

    @staticmethod
    def _extract_candidate_tokens(raw_text: str) -> List[str]:
        pieces = re.split(r"\s+|,", raw_text)
        cleaned: List[str] = []

        for piece in pieces:
            token = ScoreSheetReader._normalize_token(piece)
            if not token:
                continue
            if token.endswith(".") and token[:-1].isdigit():
                continue
            if token.isdigit():
                continue
            if SAN_LIKE_PATTERN.match(token):
                cleaned.append(token)

        return cleaned

    def extract_text(self, image_path: str) -> str:
        processed = self._preprocess_image(image_path)
        result = self.ocr.ocr(processed, cls=True)

        lines: List[str] = []
        for block in result:
            if not block:
                continue
            for item in block:
                if len(item) < 2:
                    continue
                text = item[1][0]
                lines.append(text)

        return " ".join(lines)

    @staticmethod
    def _try_repair_token(token: str) -> Sequence[str]:
        """
        Small OCR-fix candidate set for common misreads.
        Returned in priority order.
        """
        candidates = [token]
        candidates.append(token.replace("1", "l"))
        candidates.append(token.replace("l", "1"))
        candidates.append(token.replace("5", "S"))
        candidates.append(token.replace("S", "5"))
        candidates.append(token.replace("0", "O"))
        candidates.append(token.replace("O", "0"))
        # Deduplicate while preserving order.
        seen = set()
        ordered: List[str] = []
        for candidate in candidates:
            if candidate not in seen:
                seen.add(candidate)
                ordered.append(candidate)
        return ordered

    def tokens_to_pgn(self, tokens: Sequence[str]) -> str:
        game = chess.pgn.Game()
        node = game
        board = game.board()

        for token in tokens:
            applied = False
            for candidate in self._try_repair_token(token):
                try:
                    move = board.parse_san(candidate)
                    board.push(move)
                    node = node.add_variation(move)
                    applied = True
                    break
                except ValueError:
                    continue

            if not applied:
                # Skip unreadable token; pipeline still returns best possible PGN.
                continue

        exporter = chess.pgn.StringExporter(headers=False, variations=False, comments=False)
        return game.accept(exporter).strip()

    def image_to_pgn(self, image_path: str) -> str:
        raw_text = self.extract_text(image_path)
        tokens = self._extract_candidate_tokens(raw_text)
        return self.tokens_to_pgn(tokens)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Extract chess moves from scoresheet image into PGN."
    )
    parser.add_argument("image_path", help="Path to the scoresheet image")
    args = parser.parse_args()

    reader = ScoreSheetReader(language="en")
    pgn = reader.image_to_pgn(args.image_path)

    if pgn:
        print(pgn)
    else:
        print("No valid chess moves were detected.")


if __name__ == "__main__":
    main()
