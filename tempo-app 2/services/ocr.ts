import { OCRResult } from '../constants/types';

// Paul Morphy's Opera Game (1858) — famous positions all cached on Lichess
const OPERA_GAME_PGN = `[White "Paul Morphy"]
[Black "Duke of Brunswick & Count Isouard"]
[Date "1858.11.02"]
[Result "1-0"]
[Opening "Philidor Defense"]

1. e4 e5 2. Nf3 d6 3. d4 Bg4 4. dxe5 Bxf3 5. Qxf3 dxe5 6. Bc4 Nf6 7. Qb3 Qe7 8. Nc3 c6 9. Bg5 b5 10. Nxb5 cxb5 11. Bxb5+ Nbd7 12. O-O-O Rd8 13. Rxd7 Rxd7 14. Rd1 Qe6 15. Bxd7+ Nxd7 16. Qb8+ Nxb8 17. Rd8# 1-0`;

/**
 * Simulate OCR scanning — adds artificial delay, returns PGN + uncertain moves.
 * Replace this with your real Gemini / Vision API call.
 */
export async function scanScoresheet(_imageUri: string): Promise<OCRResult> {
  // Simulate network/OCR processing time
  await new Promise((res) => setTimeout(res, 2800));

  return {
    pgn: OPERA_GAME_PGN,
    uncertainMoves: [
      {
        moveIndex: 3,       // Move 4: dxe5
        detected: 'dxe5',
        alternatives: ['d5', 'dxe5', 'Nd7'],
        confidence: 0.61,
      },
      {
        moveIndex: 9,       // Move 10: Nxb5
        detected: 'Nxb5',
        alternatives: ['Nxb5', 'Nb5', 'Bxb5'],
        confidence: 0.72,
      },
      {
        moveIndex: 14,      // Move 15: Bxd7+
        detected: 'Bxd7+',
        alternatives: ['Bxd7+', 'Rxd7', 'Bd7'],
        confidence: 0.68,
      },
    ],
  };
}
