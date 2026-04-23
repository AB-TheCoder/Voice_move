# ♟ Tempo — Chess Improvement App

> *Make chess improvement frictionless.*

Tempo is a premium mobile app for chess players. Scan a handwritten scoresheet, confirm any uncertain moves, then get instant deep analysis powered by Stockfish.

---

## Screenshots / Flow

```
Scan Tab  →  Confirm Modal  →  Analysis Board
   ↓               ↓                  ↓
Take photo    Review 3 moves    Eval bar + ELO
or pick image  one at a time    Move list + engine lines
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile | React Native + Expo (TypeScript) |
| Navigation | Expo Router (file-based) |
| Chess logic | chess.js |
| Analysis | Lichess Cloud Eval API (frontend) / Stockfish (backend) |
| OCR | Mock → plug in Gemini 1.5 Pro |
| Backend | FastAPI + Python |
| Database | SQLite (dev) / PostgreSQL (prod) |
| Storage (local) | AsyncStorage |

---

## Frontend Setup

### Prerequisites
- Node.js 18+
- Expo Go app on your phone (iOS or Android)

### Install & run

```bash
cd tempo-app
npm install
npx expo start
```

Scan the QR code in Expo Go. Done ✅

### Key dependencies
```
chess.js          — PGN parsing, move validation
expo-image-picker — camera + gallery access
expo-linear-gradient — gold gradient UI
@expo/vector-icons — Ionicons
react-native-reanimated — smooth animations
```

---

## Backend Setup

### Prerequisites
- Python 3.11+
- Stockfish binary ([download](https://stockfishchess.org/download/))

```bash
cd tempo-app/backend

# Install dependencies
pip install -r requirements.txt

# (Optional) Set env vars
export GEMINI_API_KEY=your_key_here         # enables real OCR
export STOCKFISH_PATH=/usr/bin/stockfish    # if not on PATH
export DATABASE_URL=postgresql://user:pass@localhost/tempo  # or leave blank for SQLite

# Run
uvicorn main:app --reload --port 8000
```

API docs: http://localhost:8000/docs

### Routes

| Method | Path | Description |
|---|---|---|
| POST | `/ocr/scan` | Upload scoresheet image → PGN + uncertain moves |
| POST | `/analysis/analyze` | PGN → full Stockfish analysis |
| GET | `/games/` | List all saved games |
| POST | `/games/` | Save a game |
| GET | `/games/{id}` | Get one game |
| PUT | `/games/{id}` | Update a game |
| DELETE | `/games/{id}` | Delete a game |

---

## Plugging in Gemini OCR

1. Get a Gemini API key from [Google AI Studio](https://aistudio.google.com)
2. Set `GEMINI_API_KEY` in your backend environment
3. Uncomment `google-generativeai` in `requirements.txt` and `pip install` it
4. In the **frontend**, replace `services/ocr.ts` mock with a real `fetch` call:

```typescript
// services/ocr.ts
export async function scanScoresheet(imageUri: string): Promise<OCRResult> {
  const formData = new FormData();
  formData.append('file', { uri: imageUri, type: 'image/jpeg', name: 'scoresheet.jpg' } as any);

  const res = await fetch('http://YOUR_BACKEND_URL/ocr/scan', {
    method: 'POST',
    body: formData,
  });
  const data = await res.json();
  return {
    pgn: data.pgn,
    uncertainMoves: data.uncertain_moves.map((u: any) => ({
      moveIndex: u.move_index,
      detected: u.detected,
      alternatives: u.alternatives,
      confidence: u.confidence,
    })),
  };
}
```

---

## Architecture

```
tempo-app/
├── app/
│   ├── (tabs)/
│   │   ├── index.tsx       ← Home screen
│   │   ├── scan.tsx        ← Camera/gallery picker + scan states
│   │   ├── games.tsx       ← Game library
│   │   └── profile.tsx     ← Stats + settings
│   ├── confirm.tsx         ← Uncertain move review modal
│   ├── analysis.tsx        ← Full analysis board
│   └── _layout.tsx         ← Root layout
├── components/
│   ├── ChessBoard.tsx      ← 8×8 board with Unicode pieces
│   ├── EvalBar.tsx         ← Animated white/black advantage bar
│   ├── MoveList.tsx        ← Colour-coded move list
│   └── GameCard.tsx        ← Game library card
├── services/
│   ├── ocr.ts              ← Mock OCR (swap for Gemini)
│   ├── stockfish.ts        ← Lichess cloud eval + move classifier
│   ├── chess.ts            ← Opening detection, FEN helpers
│   └── storage.ts          ← AsyncStorage persistence
├── constants/
│   ├── theme.ts            ← Colors, spacing, typography
│   └── types.ts            ← Shared TypeScript types
└── backend/
    ├── main.py             ← FastAPI app
    └── routers/
        ├── ocr.py          ← /ocr/scan (Gemini or mock)
        ├── analysis.py     ← /analysis/analyze (Stockfish)
        └── games.py        ← /games CRUD (PostgreSQL/SQLite)
```

---

## Move Classification

| Symbol | Name | Centipawn Loss |
|---|---|---|
| !! | Brilliant | engine top choice, sacrificial |
| — | Good | < 50cp lost |
| ?! | Inaccuracy | 50–100cp lost |
| ? | Mistake | 100–200cp lost |
| ?? | Blunder | > 200cp lost |

---

## Contributing

1. Fork the repo
2. Create a feature branch
3. Open a PR — all improvements welcome!

---

*Built with ♟ and ☕*
