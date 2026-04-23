export type MoveClassification =
  | 'brilliant'
  | 'good'
  | 'inaccuracy'
  | 'mistake'
  | 'blunder'
  | 'book'
  | 'unknown';

export interface MoveAnalysis {
  moveIndex: number;       // 0-based
  san: string;             // Standard algebraic notation e.g. "e4"
  fen: string;             // Position after this move
  evalCp?: number;         // Centipawns (+ = white ahead)
  evalMate?: number;       // Mate in N (+ = white mates)
  classification: MoveClassification;
  bestMoveSan?: string;
  engineLines?: string[];  // Top 3 engine line strings
}

export interface UncertainMove {
  moveIndex: number;
  detected: string;          // What OCR read
  alternatives: string[];    // Other options shown to user
  confidence: number;        // 0–1
}

export interface SavedGame {
  id: string;
  pgn: string;
  whitePlayer: string;
  blackPlayer: string;
  date: string;
  result: '1-0' | '0-1' | '1/2-1/2' | '*';
  opening?: string;
  blunders: number;
  mistakes: number;
  analyzed: boolean;
  createdAt: number;       // Unix timestamp
  analysis?: MoveAnalysis[];
}

export interface OCRResult {
  pgn: string;
  uncertainMoves: UncertainMove[];
}
