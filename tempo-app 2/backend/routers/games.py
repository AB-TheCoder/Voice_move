"""
Games Router
------------
Full CRUD for saved games, backed by PostgreSQL (or SQLite for dev).

Set DATABASE_URL env var:
  PostgreSQL: postgresql://user:pass@localhost/tempo
  SQLite dev: sqlite:///./tempo.db   (default)

pip install sqlalchemy psycopg2-binary
"""

import os
from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from sqlalchemy import create_engine, Column, String, Integer, Boolean, Text, Float, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session

router = APIRouter()

# ── DB setup ──────────────────────────────────────────────────────────────────

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./tempo.db")
engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False} if "sqlite" in DATABASE_URL else {},
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


class GameModel(Base):
    __tablename__ = "games"

    id = Column(String, primary_key=True, index=True)
    pgn = Column(Text, nullable=False)
    white_player = Column(String, default="White")
    black_player = Column(String, default="Black")
    date = Column(String, default="")
    result = Column(String, default="*")
    opening = Column(String, default="Unknown Opening")
    blunders = Column(Integer, default=0)
    mistakes = Column(Integer, default=0)
    inaccuracies = Column(Integer, default=0)
    analyzed = Column(Boolean, default=False)
    analysis_json = Column(Text, nullable=True)   # JSON blob
    created_at = Column(DateTime, default=datetime.utcnow)


Base.metadata.create_all(bind=engine)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ── Pydantic schemas ──────────────────────────────────────────────────────────

class GameCreate(BaseModel):
    id: str
    pgn: str
    white_player: str = "White"
    black_player: str = "Black"
    date: str = ""
    result: str = "*"
    opening: str = "Unknown Opening"
    blunders: int = 0
    mistakes: int = 0
    inaccuracies: int = 0
    analyzed: bool = False
    analysis_json: Optional[str] = None


class GameOut(GameCreate):
    created_at: datetime

    class Config:
        from_attributes = True


# ── Routes ────────────────────────────────────────────────────────────────────

@router.get("/", response_model=List[GameOut])
def list_games(skip: int = 0, limit: int = 50, db: Session = Depends(get_db)):
    return db.query(GameModel).order_by(GameModel.created_at.desc()).offset(skip).limit(limit).all()


@router.get("/{game_id}", response_model=GameOut)
def get_game(game_id: str, db: Session = Depends(get_db)):
    game = db.query(GameModel).filter(GameModel.id == game_id).first()
    if not game:
        raise HTTPException(status_code=404, detail="Game not found")
    return game


@router.post("/", response_model=GameOut)
def create_game(game: GameCreate, db: Session = Depends(get_db)):
    existing = db.query(GameModel).filter(GameModel.id == game.id).first()
    if existing:
        # Upsert
        for k, v in game.dict().items():
            setattr(existing, k, v)
        db.commit()
        db.refresh(existing)
        return existing

    db_game = GameModel(**game.dict())
    db.add(db_game)
    db.commit()
    db.refresh(db_game)
    return db_game


@router.put("/{game_id}", response_model=GameOut)
def update_game(game_id: str, game: GameCreate, db: Session = Depends(get_db)):
    db_game = db.query(GameModel).filter(GameModel.id == game_id).first()
    if not db_game:
        raise HTTPException(status_code=404, detail="Game not found")
    for k, v in game.dict().items():
        setattr(db_game, k, v)
    db.commit()
    db.refresh(db_game)
    return db_game


@router.delete("/{game_id}")
def delete_game(game_id: str, db: Session = Depends(get_db)):
    db_game = db.query(GameModel).filter(GameModel.id == game_id).first()
    if not db_game:
        raise HTTPException(status_code=404, detail="Game not found")
    db.delete(db_game)
    db.commit()
    return {"deleted": game_id}
