"""
Analysis Router
---------------
POST /analysis/analyze   — accepts PGN, runs Stockfish, returns move analysis.

Requires stockfish binary on PATH.
Install: https://stockfishchess.org/download/  or  apt install stockfish
pip install chess stockfish
"""

import os
from typing import List, Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter()


# ── Pydantic models ───────────────────────────────────────────────────────────

class AnalysisRequest(BaseModel):
    pgn: str
    depth: int = 18          # Stockfish depth per position
    multi_pv: int = 3        # Number of engine lines


class MoveAnalysis(BaseModel):
    move_index: int
    san: str
    fen: str
    eval_cp: Optional[int] = None
    eval_mate: Optional[int] = None
    classification: str      # brilliant | good | inaccuracy | mistake | blunder | book | unknown
    best_move_san: Optional[str] = None
    engine_lines: List[str] = []


class AnalysisResponse(BaseModel):
    moves: List[MoveAnalysis]
    opening: str
    blunders: int
    mistakes: int
    inaccuracies: int


# ── Opening detection ─────────────────────────────────────────────────────────

OPENINGS: list[tuple[str, str]] = [
    ("e4 e5 Nf3 Nc6 Bb5", "Ruy López"),
    ("e4 e5 Nf3 Nc6 Bc4", "Italian Game"),
    ("e4 c5", "Sicilian Defense"),
    ("e4 e6", "French Defense"),
    ("e4 c6", "Caro-Kann Defense"),
    ("d4 d5 c4", "Queen's Gambit"),
    ("d4 Nf6 c4 e6 Nc3 Bb4", "Nimzo-Indian Defense"),
    ("d4 Nf6 c4 g6", "King's Indian Defense"),
    ("e4 e5 f4", "King's Gambit"),
    ("Nf3", "Réti Opening"),
    ("c4", "English Opening"),
    ("e4", "King's Pawn Opening"),
    ("d4", "Queen's Pawn Opening"),
]


def detect_opening_from_moves(move_list: list[str]) -> str:
    for key, name in OPENINGS:
        key_moves = key.split()
        if len(key_moves) <= len(move_list) and all(
            key_moves[i] == move_list[i] for i in range(len(key_moves))
        ):
            return name
    return "Unknown Opening"


# ── Move classifier ───────────────────────────────────────────────────────────

def classify_move(prev_cp: Optional[int], curr_cp: Optional[int], side: str) -> str:
    """side = 'w' or 'b' — the side that just moved."""
    if prev_cp is None or curr_cp is None:
        return "unknown"
    delta = (curr_cp - prev_cp) if side == "w" else (prev_cp - curr_cp)
    if delta >= -50:
        return "good"
    if delta >= -100:
        return "inaccuracy"
    if delta >= -200:
        return "mistake"
    return "blunder"


# ── Stockfish analysis ────────────────────────────────────────────────────────

def run_stockfish_analysis(pgn: str, depth: int, multi_pv: int) -> AnalysisResponse:
    try:
        import chess
        import chess.pgn
        import chess.engine
        import io
    except ImportError:
        raise HTTPException(status_code=500, detail="python-chess not installed. Run: pip install chess")

    stockfish_path = os.getenv("STOCKFISH_PATH", "stockfish")

    try:
        engine = chess.engine.SimpleEngine.popen_uci(stockfish_path)
    except FileNotFoundError:
        raise HTTPException(
            status_code=500,
            detail="Stockfish binary not found. Set STOCKFISH_PATH env var or install stockfish.",
        )

    try:
        game = chess.pgn.read_game(io.StringIO(pgn))
        if game is None:
            raise HTTPException(status_code=400, detail="Invalid PGN")

        board = game.board()
        moves_node = list(game.mainline_moves())
        results: List[MoveAnalysis] = []
        prev_cp: Optional[int] = None
        move_sans: list[str] = []

        for i, move in enumerate(moves_node):
            san = board.san(move)
            side = "w" if board.turn == chess.WHITE else "b"
            board.push(move)
            move_sans.append(san)

            info = engine.analyse(board, chess.engine.Limit(depth=depth), multipv=multi_pv)

            # Extract top line eval
            top = info[0] if isinstance(info, list) else info
            score = top["score"].white()
            curr_cp: Optional[int] = None
            curr_mate: Optional[int] = None

            if score.is_mate():
                curr_mate = score.mate()
            else:
                curr_cp = score.score()

            # Engine lines
            lines: list[str] = []
            infos = info if isinstance(info, list) else [info]
            for pv_info in infos:
                pv_score = pv_info["score"].white()
                if pv_score.is_mate():
                    s = f"#{pv_score.mate()}"
                else:
                    v = pv_score.score() or 0
                    s = f"{'+' if v >= 0 else ''}{v/100:.2f}"
                pv_moves = [board.san(m) for m in pv_info.get("pv", [])[:5]]
                lines.append(f"{s} {' '.join(pv_moves)}")

            best_san: Optional[str] = None
            if infos and infos[0].get("pv"):
                try:
                    best_san = board.san(infos[0]["pv"][0])
                except Exception:
                    pass

            classification = classify_move(prev_cp, curr_cp, side)
            prev_cp = curr_cp

            results.append(
                MoveAnalysis(
                    move_index=i,
                    san=san,
                    fen=board.fen(),
                    eval_cp=curr_cp,
                    eval_mate=curr_mate,
                    classification=classification,
                    best_move_san=best_san,
                    engine_lines=lines,
                )
            )

        opening = detect_opening_from_moves(move_sans)
        blunders = sum(1 for m in results if m.classification == "blunder")
        mistakes = sum(1 for m in results if m.classification == "mistake")
        inaccuracies = sum(1 for m in results if m.classification == "inaccuracy")

        return AnalysisResponse(
            moves=results,
            opening=opening,
            blunders=blunders,
            mistakes=mistakes,
            inaccuracies=inaccuracies,
        )

    finally:
        engine.quit()


# ── Route ─────────────────────────────────────────────────────────────────────

@router.post("/analyze", response_model=AnalysisResponse)
def analyze_game(req: AnalysisRequest):
    """Analyze a PGN with Stockfish. Requires stockfish binary on PATH."""
    return run_stockfish_analysis(req.pgn, req.depth, req.multi_pv)
