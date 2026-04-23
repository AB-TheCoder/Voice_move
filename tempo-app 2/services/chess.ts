import { Chess } from 'chess.js';

// Common openings keyed by first moves (space-separated SANs)
const OPENING_MAP: [string, string][] = [
  ["e4 e5 Nf3 Nc6 Bb5", "Ruy López"],
  ["e4 e5 Nf3 Nc6 Bc4", "Italian Game"],
  ["e4 e5 Nf3 Nc6 Bc4 Bc5", "Giuoco Piano"],
  ["e4 e5 Nf3 Nc6 d4", "Scotch Game"],
  ["e4 e5 Nf3 Nf6", "Petrov Defense"],
  ["e4 e5 f4", "King's Gambit"],
  ["e4 e5 Nf3 d6", "Philidor Defense"],
  ["e4 c5", "Sicilian Defense"],
  ["e4 c5 Nf3 d6 d4 cxd4 Nxd4 Nf6 Nc3 a6", "Sicilian Najdorf"],
  ["e4 c6", "Caro-Kann Defense"],
  ["e4 e6", "French Defense"],
  ["e4 d5", "Scandinavian Defense"],
  ["d4 d5 c4", "Queen's Gambit"],
  ["d4 d5 c4 e6", "Queen's Gambit Declined"],
  ["d4 d5 c4 dxc4", "Queen's Gambit Accepted"],
  ["d4 Nf6 c4 e6 Nc3 Bb4", "Nimzo-Indian Defense"],
  ["d4 Nf6 c4 g6", "King's Indian Defense"],
  ["d4 Nf6 c4 e6 g3", "Catalan Opening"],
  ["d4 d5", "Queen's Pawn Game"],
  ["e4 e5", "King's Pawn Game"],
  ["e4", "King's Pawn Opening"],
  ["d4", "Queen's Pawn Opening"],
  ["c4", "English Opening"],
  ["Nf3", "Réti Opening"],
];

/** Detect opening name from PGN or move list */
export function detectOpening(pgn: string): string {
  try {
    const chess = new Chess();
    chess.loadPgn(pgn);
    const moves = chess.history();

    for (const [key, name] of OPENING_MAP) {
      const keyMoves = key.split(' ');
      if (
        keyMoves.length <= moves.length &&
        keyMoves.every((m, i) => m === moves[i])
      ) {
        return name;
      }
    }
    return 'Unknown Opening';
  } catch {
    return 'Unknown Opening';
  }
}

/** Parse PGN header tags */
export function parsePgnHeaders(pgn: string): Record<string, string> {
  const headers: Record<string, string> = {};
  const regex = /\[(\w+)\s+"([^"]*)"\]/g;
  let match;
  while ((match = regex.exec(pgn)) !== null) {
    headers[match[1]] = match[2];
  }
  return headers;
}

/** Get all FENs (including starting position) from a PGN */
export function getFensFromPgn(pgn: string): string[] {
  const chess = new Chess();
  try {
    chess.loadPgn(pgn);
  } catch {
    return [];
  }
  const history = chess.history({ verbose: true });
  chess.reset();
  const fens: string[] = [chess.fen()];
  for (const move of history) {
    chess.move(move.san);
    fens.push(chess.fen());
  }
  return fens;
}

/** Parse FEN and return board array[8][8] of piece codes like 'wK', 'bP', null */
export function parseFenToBoard(fen: string): (string | null)[][] {
  const board: (string | null)[][] = Array.from({ length: 8 }, () =>
    Array(8).fill(null)
  );
  const position = fen.split(' ')[0];
  const rows = position.split('/');

  for (let r = 0; r < 8; r++) {
    let c = 0;
    for (const ch of rows[r]) {
      if (ch >= '1' && ch <= '8') {
        c += parseInt(ch, 10);
      } else {
        const color = ch === ch.toUpperCase() ? 'w' : 'b';
        const type = ch.toUpperCase();
        board[r][c] = `${color}${type}`;
        c++;
      }
    }
  }
  return board;
}

export function evalLabel(cp?: number, mate?: number): string {
  if (mate != null) return mate > 0 ? `M${mate}` : `-M${Math.abs(mate)}`;
  if (cp == null) return '0.00';
  const val = cp / 100;
  return (val > 0 ? '+' : '') + val.toFixed(2);
}

/** Returns 0..1 white advantage for eval bar (0.5 = equal) */
export function evalToBarRatio(cp?: number, mate?: number): number {
  if (mate != null) return mate > 0 ? 0.98 : 0.02;
  if (cp == null) return 0.5;
  // Sigmoid mapping: ±500cp → ~90% bar
  return 1 / (1 + Math.exp(-cp / 250));
}
