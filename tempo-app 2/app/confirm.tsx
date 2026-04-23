import React, { useEffect, useState } from 'react';
import {
  View, Text, TouchableOpacity, StyleSheet,
  ScrollView, ActivityIndicator, Alert,
} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { router } from 'expo-router';
import { Chess } from 'chess.js';
import { Colors, Spacing, Radius, Typography } from '../constants/theme';
import { OCRResult, UncertainMove } from '../constants/types';
import { saveGame, generateId } from '../services/storage';
import { detectOpening, parsePgnHeaders, getFensFromPgn } from '../services/chess';
import ChessBoard from '../components/ChessBoard';

export default function ConfirmScreen() {
  const [ocrResult, setOcrResult] = useState<OCRResult | null>(null);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [resolvedMoves, setResolvedMoves] = useState<Record<number, string>>({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    AsyncStorage.getItem('tempo:pendingOcr').then((raw) => {
      if (raw) setOcrResult(JSON.parse(raw));
      setLoading(false);
    });
  }, []);

  if (loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator color={Colors.gold} />
      </View>
    );
  }

  if (!ocrResult) {
    return (
      <View style={styles.center}>
        <Text style={styles.errorText}>No scan data found. Please scan again.</Text>
      </View>
    );
  }

  const uncertain = ocrResult.uncertainMoves;

  // If no uncertain moves, skip straight to saving
  if (uncertain.length === 0) {
    handleSave(ocrResult.pgn, {});
    return <View style={styles.center}><ActivityIndicator color={Colors.gold} /></View>;
  }

  const current: UncertainMove = uncertain[currentIndex];
  const progress = currentIndex / uncertain.length;

  // Get the board position just before this uncertain move
  const fens = getFensFromPgn(ocrResult.pgn);
  const boardFen = fens[current.moveIndex] ?? fens[fens.length - 1];

  function selectMove(san: string) {
    const updated = { ...resolvedMoves, [current.moveIndex]: san };
    setResolvedMoves(updated);

    if (currentIndex + 1 < uncertain.length) {
      setCurrentIndex(currentIndex + 1);
    } else {
      // All confirmed — save and go to analysis
      handleSave(ocrResult!.pgn, updated);
    }
  }

  async function handleSave(pgn: string, corrections: Record<number, string>) {
    // Apply corrections to PGN
    let finalPgn = pgn;
    if (Object.keys(corrections).length > 0) {
      const chess = new Chess();
      try {
        chess.loadPgn(pgn);
        const moves = chess.history();
        Object.entries(corrections).forEach(([idx, san]) => {
          moves[parseInt(idx)] = san;
        });
        chess.reset();
        for (const san of moves) {
          try { chess.move(san); } catch { break; }
        }
        finalPgn = chess.pgn();
      } catch { /* use original */ }
    }

    const headers = parsePgnHeaders(finalPgn);
    const opening = detectOpening(finalPgn);

    const chess = new Chess();
    try { chess.loadPgn(finalPgn); } catch {}

    const game = {
      id: generateId(),
      pgn: finalPgn,
      whitePlayer: headers['White'] ?? 'White',
      blackPlayer: headers['Black'] ?? 'Black',
      date: headers['Date'] ?? new Date().toISOString().slice(0, 10),
      result: (headers['Result'] as any) ?? '*',
      opening,
      blunders: 0,
      mistakes: 0,
      analyzed: false,
      createdAt: Date.now(),
    };

    await saveGame(game);
    await AsyncStorage.removeItem('tempo:pendingOcr');

    router.replace({ pathname: '/analysis', params: { gameId: game.id } });
  }

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
      {/* Progress bar */}
      <View style={styles.progressOuter}>
        <View style={[styles.progressInner, { width: `${progress * 100}%` }]} />
      </View>
      <Text style={styles.progressLabel}>
        Move {currentIndex + 1} of {uncertain.length}
      </Text>

      <Text style={styles.heading}>Confirm Uncertain Move</Text>
      <Text style={styles.subheading}>
        OCR detected <Text style={styles.detectedMove}>"{current.detected}"</Text> with{' '}
        {Math.round(current.confidence * 100)}% confidence. Which move was played?
      </Text>

      {/* Board showing position before uncertain move */}
      <View style={styles.boardWrapper}>
        <ChessBoard fen={boardFen} />
      </View>
      <Text style={styles.boardCaption}>Position before move {Math.floor(current.moveIndex / 2) + 1}</Text>

      {/* Move options */}
      <View style={styles.options}>
        {current.alternatives.map((alt) => {
          const isDetected = alt === current.detected;
          return (
            <TouchableOpacity
              key={alt}
              style={[styles.optionBtn, isDetected && styles.optionBtnHighlighted]}
              onPress={() => selectMove(alt)}
              activeOpacity={0.8}
            >
              {isDetected ? (
                <LinearGradient
                  colors={[Colors.goldBright + '22', Colors.gold + '11']}
                  style={styles.optionInner}
                >
                  <Text style={[styles.optionSan, isDetected && styles.optionSanHighlighted]}>
                    {alt}
                  </Text>
                  <View style={styles.ocrBadge}>
                    <Text style={styles.ocrBadgeText}>OCR Detected</Text>
                  </View>
                </LinearGradient>
              ) : (
                <View style={styles.optionInner}>
                  <Text style={styles.optionSan}>{alt}</Text>
                </View>
              )}
            </TouchableOpacity>
          );
        })}
      </View>

      {/* Skip */}
      <TouchableOpacity
        style={styles.skipBtn}
        onPress={() => selectMove(current.detected)}
      >
        <Text style={styles.skipText}>Keep OCR reading "{current.detected}"</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: Colors.bg },
  content: { padding: Spacing.md, paddingBottom: 48, gap: Spacing.md },
  center: { flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: Colors.bg },
  errorText: { ...Typography.body, color: Colors.blunder },

  progressOuter: {
    height: 3, backgroundColor: Colors.cardBorder,
    borderRadius: 2, overflow: 'hidden',
  },
  progressInner: { height: '100%', backgroundColor: Colors.gold, borderRadius: 2 },
  progressLabel: { ...Typography.tiny, color: Colors.textMuted, textAlign: 'right' },

  heading: { ...Typography.title, color: Colors.textPrimary },
  subheading: { ...Typography.body, color: Colors.textSecondary, lineHeight: 22 },
  detectedMove: { color: Colors.gold, fontWeight: '700' },

  boardWrapper: { alignSelf: 'center' },
  boardCaption: { ...Typography.tiny, color: Colors.textMuted, textAlign: 'center', marginTop: 4 },

  options: { gap: Spacing.sm },
  optionBtn: {
    borderRadius: Radius.md, overflow: 'hidden',
    borderWidth: 1, borderColor: Colors.cardBorder,
    backgroundColor: Colors.card,
  },
  optionBtnHighlighted: { borderColor: Colors.gold + '88' },
  optionInner: { padding: Spacing.md, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  optionSan: { ...Typography.subtitle, fontSize: 22, color: Colors.textPrimary, fontFamily: 'monospace' },
  optionSanHighlighted: { color: Colors.goldBright },
  ocrBadge: {
    backgroundColor: Colors.gold + '22', borderRadius: Radius.sm,
    paddingHorizontal: 8, paddingVertical: 3, borderWidth: 1, borderColor: Colors.gold + '55',
  },
  ocrBadgeText: { ...Typography.tiny, color: Colors.gold, fontWeight: '700' },

  skipBtn: {
    alignItems: 'center', padding: Spacing.md,
    borderWidth: 1, borderColor: Colors.cardBorder,
    borderRadius: Radius.md,
  },
  skipText: { ...Typography.caption, color: Colors.textMuted },
});
