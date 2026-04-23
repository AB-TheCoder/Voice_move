import React, { useMemo } from 'react';
import { View, Text, StyleSheet, Dimensions } from 'react-native';
import { Colors } from '../constants/theme';
import { parseFenToBoard } from '../services/chess';

const BOARD_SIZE = Dimensions.get('window').width - 32;
const SQUARE_SIZE = BOARD_SIZE / 8;

const PIECE_SYMBOLS: Record<string, string> = {
  wK: '♔', wQ: '♕', wR: '♖', wB: '♗', wN: '♘', wP: '♙',
  bK: '♚', bQ: '♛', bR: '♜', bB: '♝', bN: '♞', bP: '♟',
};

const FILES = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
const RANKS = ['8', '7', '6', '5', '4', '3', '2', '1'];

interface HighlightSquares {
  from?: string;   // e.g. 'e2'
  to?: string;     // e.g. 'e4'
  check?: string;  // king in check
}

interface Props {
  fen: string;
  highlights?: HighlightSquares;
  flipped?: boolean;
}

function squareName(row: number, col: number, flipped: boolean): string {
  const file = flipped ? FILES[7 - col] : FILES[col];
  const rank = flipped ? RANKS[7 - row] : RANKS[row];
  return `${file}${rank}`;
}

export default function ChessBoard({ fen, highlights = {}, flipped = false }: Props) {
  const board = useMemo(() => parseFenToBoard(fen), [fen]);

  const displayBoard = flipped
    ? [...board].reverse().map((row) => [...row].reverse())
    : board;

  return (
    <View style={styles.wrapper}>
      {/* Rank labels */}
      <View style={styles.rankLabels}>
        {RANKS.map((r) => (
          <View key={r} style={styles.rankLabel}>
            <Text style={styles.coordText}>{flipped ? RANKS[7 - RANKS.indexOf(r)] : r}</Text>
          </View>
        ))}
      </View>

      <View style={styles.boardContainer}>
        {/* Board */}
        <View style={styles.board}>
          {displayBoard.map((row, rowIdx) => (
            <View key={rowIdx} style={styles.row}>
              {row.map((piece, colIdx) => {
                const sq = squareName(rowIdx, colIdx, flipped);
                const isLight = (rowIdx + colIdx) % 2 === 0;
                const isHighlightFrom = sq === highlights.from;
                const isHighlightTo = sq === highlights.to;
                const isCheck = sq === highlights.check;

                let bgColor = isLight ? Colors.lightSquare : Colors.darkSquare;
                if (isHighlightFrom || isHighlightTo) {
                  bgColor = isLight ? '#F6F66999' : '#BACA2B99';
                }
                if (isCheck) bgColor = '#FF4444AA';

                return (
                  <View
                    key={colIdx}
                    style={[
                      styles.square,
                      { backgroundColor: bgColor },
                    ]}
                  >
                    {piece && (
                      <Text
                        style={[
                          styles.piece,
                          piece.startsWith('w') ? styles.whitePiece : styles.blackPiece,
                        ]}
                        adjustsFontSizeToFit
                      >
                        {PIECE_SYMBOLS[piece] ?? ''}
                      </Text>
                    )}
                    {/* Corner coordinate hints */}
                    {colIdx === 0 && (
                      <Text style={[styles.cornerCoord, styles.cornerRank]}>
                        {flipped ? (rowIdx + 1) : (8 - rowIdx)}
                      </Text>
                    )}
                    {rowIdx === 7 && (
                      <Text style={[styles.cornerCoord, styles.cornerFile]}>
                        {flipped ? FILES[7 - colIdx] : FILES[colIdx]}
                      </Text>
                    )}
                  </View>
                );
              })}
            </View>
          ))}
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    flexDirection: 'row',
    alignSelf: 'center',
  },
  rankLabels: {
    width: 0, // hidden; we use corner coords instead
  },
  rankLabel: {
    height: SQUARE_SIZE,
    justifyContent: 'center',
  },
  coordText: {
    fontSize: 9,
    color: Colors.textMuted,
    fontWeight: '600',
  },
  boardContainer: {
    borderWidth: 2,
    borderColor: Colors.boardBorder,
    borderRadius: 4,
    overflow: 'hidden',
    shadowColor: Colors.gold,
    shadowOpacity: 0.3,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 4 },
    elevation: 8,
  },
  board: {
    width: BOARD_SIZE,
    height: BOARD_SIZE,
  },
  row: {
    flexDirection: 'row',
  },
  square: {
    width: SQUARE_SIZE,
    height: SQUARE_SIZE,
    justifyContent: 'center',
    alignItems: 'center',
    position: 'relative',
  },
  piece: {
    fontSize: SQUARE_SIZE * 0.72,
    lineHeight: SQUARE_SIZE * 0.9,
    textAlign: 'center',
  },
  whitePiece: {
    color: '#FFFEF0',
    textShadowColor: 'rgba(0,0,0,0.6)',
    textShadowOffset: { width: 0.5, height: 1 },
    textShadowRadius: 2,
  },
  blackPiece: {
    color: '#1A0F00',
    textShadowColor: 'rgba(255,255,255,0.15)',
    textShadowOffset: { width: 0.5, height: 0.5 },
    textShadowRadius: 1,
  },
  cornerCoord: {
    position: 'absolute',
    fontSize: 8,
    fontWeight: '700',
    opacity: 0.7,
  },
  cornerRank: {
    top: 2,
    left: 3,
    color: '#8B5A2B',
  },
  cornerFile: {
    bottom: 2,
    right: 3,
    color: '#8B5A2B',
  },
});
