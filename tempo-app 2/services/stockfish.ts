import { MoveAnalysis, MoveClassification } from '../constants/types';
import { Chess } from 'chess.js';

export interface CloudEval {
  cp?: number;
  mate?: number;
  depth: number;
  bestMoveSan?: string;
  lines: string[];
}

/** Fetch eval from Lichess cloud database (cached positions, depth ~40) */
export async function getCloudEval(fen: string): Promise<CloudEval | null> {
  try {
    const url = `https://lichess.org/api/cloud-eval?fen=${encodeURIComponent(fen)}&multiPv=3`;
    const res = await fetch(url, {
      headers: { Accept: 'application/json' },
    });
    if (!res.ok) return null;
    const data = await res.json();

    if (!data.pvs || data.pvs.length === 0) return null;

    const lines: string[] = data.pvs.map((pv: any) => {
      const score =
        pv.mate != null
          ? `#${pv.mate}`
          : `${pv.cp != null ? (pv.cp / 100).toFixed(2) : '?'}`;
      return `${score} ${pv.moves ?? ''}`;
    });

    return {
      cp: data.pvs[0]?.cp,
      mate: data.pvs[0]?.mate,
      depth: data.depth ?? 0,
      bestMoveSan: data.pvs[0]?.moves?.split(' ')[0] ?? undefined,
      lines,
    };
  } catch {
    return null;
  }
}

function classifyMove(
  prevCp: number | undefined,
  currCp: number | undefined,
  sideToMove: 'w' | 'b' // side that JUST moved
): MoveClassification {
  if (prevCp == null || currCp == null) return 'unknown';

  // From the perspective of the side that just moved:
  // White just moved → board eval went UP = good for white
  // Black just moved → board eval went DOWN = good for black
  const delta = sideToMove === 'w' ? currCp - prevCp : prevCp - currCp;

  if (delta >= 0) return 'good';
  if (delta >= -50) return 'good';
  if (delta >= -100) return 'inaccuracy';
  if (delta >= -200) return 'mistake';
  return 'blunder';
}

/** Full game analysis: walk through every position, fetch evals, classify moves */
export async function analyzeGame(
  pgn: string,
  onProgress?: (current: number, total: number) => void
): Promise<MoveAnalysis[]> {
  const chess = new Chess();
  try {
    chess.loadPgn(pgn);
  } catch {
    return [];
  }

  const history = chess.history({ verbose: true });
  const total = history.length;

  // Replay from start to collect FENs
  chess.reset();
  const fens: string[] = [chess.fen()]; // position before each move
  for (const move of history) {
    chess.move(move.san);
    fens.push(chess.fen());
  }

  const results: MoveAnalysis[] = [];
  const evals: (CloudEval | null)[] = new Array(fens.length).fill(null);

  // Fetch evals sequentially with small delay to respect Lichess rate limits
  for (let i = 0; i < fens.length; i++) {
    onProgress?.(i, total);
    evals[i] = await getCloudEval(fens[i]);
    if (i < fens.length - 1) {
      await new Promise((r) => setTimeout(r, 120)); // ~8 req/s
    }
  }

  onProgress?.(total, total);

  for (let i = 0; i < history.length; i++) {
    const move = history[i];
    const prevEval = evals[i];
    const currEval = evals[i + 1];

    // Determine which side just moved: if i is even, white moved (0-indexed)
    const sideToMove: 'w' | 'b' = i % 2 === 0 ? 'w' : 'b';

    const classification = classifyMove(prevEval?.cp, currEval?.cp, sideToMove);

    results.push({
      moveIndex: i,
      san: move.san,
      fen: fens[i + 1],
      evalCp: currEval?.cp,
      evalMate: currEval?.mate,
      classification,
      bestMoveSan: currEval?.bestMoveSan,
      engineLines: currEval?.lines,
    });
  }

  return results;
}
