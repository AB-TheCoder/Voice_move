from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import ocr, analysis, games

app = FastAPI(
    title="Tempo Chess API",
    description="Backend for the Tempo chess improvement app",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(ocr.router, prefix="/ocr", tags=["OCR"])
app.include_router(analysis.router, prefix="/analysis", tags=["Analysis"])
app.include_router(games.router, prefix="/games", tags=["Games"])


@app.get("/health")
def health():
    return {"status": "ok", "version": "1.0.0"}
