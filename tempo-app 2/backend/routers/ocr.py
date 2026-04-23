"""
OCR Router
----------
POST /ocr/scan   — accepts a scoresheet image, returns PGN + uncertain moves.

To enable real OCR, set GEMINI_API_KEY in your environment and install:
    pip install google-generativeai

The mock below returns Morphy's Opera Game so you can test the full flow.
"""

import os
import base64
from fastapi import APIRouter, UploadFile, File, HTTPException
from pydantic import BaseModel
from typing import List

router = APIRouter()


# ── Pydantic models ──────────────────────────────────────────────────────────

class UncertainMove(BaseModel):
    move_index: int
    detected: str
    alternatives: List[str]
    confidence: float


class OCRResponse(BaseModel):
    pgn: str
    uncertain_moves: List[UncertainMove]
    method: str  # "gemini" | "mock"


# ── Mock PGN (Opera Game) ────────────────────────────────────────────────────

MOCK_PGN = """\
[White "Paul Morphy"]
[Black "Duke of Brunswick & Count Isouard"]
[Date "1858.11.02"]
[Result "1-0"]
[Opening "Philidor Defense"]

1. e4 e5 2. Nf3 d6 3. d4 Bg4 4. dxe5 Bxf3 5. Qxf3 dxe5 6. Bc4 Nf6 \
7. Qb3 Qe7 8. Nc3 c6 9. Bg5 b5 10. Nxb5 cxb5 11. Bxb5+ Nbd7 \
12. O-O-O Rd8 13. Rxd7 Rxd7 14. Rd1 Qe6 15. Bxd7+ Nxd7 \
16. Qb8+ Nxb8 17. Rd8# 1-0"""

MOCK_UNCERTAIN: List[UncertainMove] = [
    UncertainMove(move_index=3, detected="dxe5", alternatives=["d5", "dxe5", "Nd7"], confidence=0.61),
    UncertainMove(move_index=9, detected="Nxb5", alternatives=["Nxb5", "Nb5", "Bxb5"], confidence=0.72),
    UncertainMove(move_index=14, detected="Bxd7+", alternatives=["Bxd7+", "Rxd7", "Bd7"], confidence=0.68),
]


# ── Gemini OCR (real implementation) ─────────────────────────────────────────

GEMINI_PROMPT = """You are a chess scoresheet OCR expert.
Analyze this image of a handwritten chess scoresheet and extract the game moves.

Return ONLY valid JSON in this exact schema:
{
  "pgn": "<full PGN string with headers>",
  "uncertain_moves": [
    {
      "move_index": <0-based integer>,
      "detected": "<most likely SAN>",
      "alternatives": ["<option1>", "<option2>", "<option3>"],
      "confidence": <0.0-1.0>
    }
  ]
}

Rules:
- Include all PGN headers you can read (White, Black, Date, Result, Event).
- Flag any move where your confidence is below 0.80 as uncertain.
- Provide 2-3 plausible alternative moves for each uncertain entry.
- Return ONLY the JSON object, no markdown fences."""


async def run_gemini_ocr(image_bytes: bytes, mime_type: str) -> OCRResponse:
    import google.generativeai as genai  # type: ignore
    import json

    genai.configure(api_key=os.environ["GEMINI_API_KEY"])
    model = genai.GenerativeModel("gemini-1.5-pro-latest")

    b64 = base64.b64encode(image_bytes).decode()
    response = model.generate_content(
        [
            {"inline_data": {"mime_type": mime_type, "data": b64}},
            GEMINI_PROMPT,
        ]
    )
    raw = response.text.strip()
    # Strip any accidental markdown fences
    if raw.startswith("```"):
        raw = raw.split("```")[1].lstrip("json").strip()

    data = json.loads(raw)
    uncertain = [UncertainMove(**u) for u in data.get("uncertain_moves", [])]
    return OCRResponse(pgn=data["pgn"], uncertain_moves=uncertain, method="gemini")


# ── Route ─────────────────────────────────────────────────────────────────────

@router.post("/scan", response_model=OCRResponse)
async def scan_scoresheet(file: UploadFile = File(...)):
    """Upload a scoresheet image. Returns PGN + flagged uncertain moves."""
    contents = await file.read()
    if not contents:
        raise HTTPException(status_code=400, detail="Empty file")

    mime = file.content_type or "image/jpeg"
    if not mime.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")

    # Use real Gemini if key is present, otherwise mock
    if os.getenv("GEMINI_API_KEY"):
        try:
            return await run_gemini_ocr(contents, mime)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"OCR failed: {e}")

    # Mock response
    return OCRResponse(pgn=MOCK_PGN, uncertain_moves=MOCK_UNCERTAIN, method="mock")
