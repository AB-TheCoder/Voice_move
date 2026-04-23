import React, { useEffect, useRef, useState } from 'react';
import {
  View, Text, ScrollView, TouchableOpacity,
  StyleSheet, ActivityIndicator, Dimensions,
} from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { Chess } from 'chess.js';
import { Colors, Spacing, Radius, Typography } from '../constants/theme';
import { getGame, saveGame } from '../services/storage';
import { analyzeGame } from '../services/stockfish';
import { getFensFromPgn, evalLabel } from '../services/chess';
import { SavedGame, MoveAnalysis, MoveClassification } from '../constants/types';
import ChessBoard from '../components/ChessBoard';
import EvalBar from '../components/EvalBar';
import MoveList from '../components/MoveList';

const { width } = Dimensions.get('window');

type AnalysisState = 'loading' | 'analyzing' | 'ready' | 'error';

const CLASSIFICATION_LABEL: Record<MoveClassification, string> = {
  brilliant: '!! Brilliant',
  good: 'Good move',
  inaccuracy: '?! Inaccuracy',
  mistake: '? Mistake',
  blunder: '?? Blunder',
  book: 'Book move',
  unknown: '—',
};

const CLASSIFICATION_COLOR: Record<MoveClassification, string> = {
  brilliant: Colors.brilliant,
  good: Colors.good,
  inaccuracy: Colors.inaccuracy,
  mistake: Colors.mistake,
  blunder: Colors.blunder,
  book: Colors.textMuted,
  unknown: Colors.textSecondary,
};

export default function AnalysisScreen() {
  const { gameId } = useLocalSearchParams<{ gameId: string }>();
  const [game, setGame] = useState<SavedGame | null>(null);
  const [analysis, setAnalysis] = useState<MoveAnalysis[]>([]);
  const [state, setState] = useState<AnalysisState>('loading');
  const [progress, setProgress] = useState({ current: 0, total: 0 });
  const [moveIndex, setMoveIndex] = useState(-1); // -1 = starting position
  const [flipped, setFlipped] = useState(false);

  const fensRef = useRef<string[]>([]);

  useEffect(() => {
    if (!gameId) return;
    loadAndAnalyze(gameId);
  }, [gameId]);

  async function loadAndAnalyze(id: string) {
    setState('loading');
    const g = await getGame(id);
    if (!g) { setState('error'); return; }
    setGame(g);

    const fens = getFensFromPgn(g.pgn);
    fensRef.current = fens;

    if (g.analyzed && g.analysis) {
      setAnalysis(g.analysis);
      setState('ready');
      return;
    }

    // Run analysis
    setState('analyzing');
    try {
      const result = await analyzeGame(g.pgn, (cur, tot) =>
        setProgress({ current: cur, total: tot })
      );
      setAnalysis(result);

      const blunders = result.filter((m) => m.classification === 'blunder').length;
      const mistakes = result.filter((m) => m.classification === 'mistake').length;

      const updated: SavedGame = {
        ...g,
        analysis: result,
        analyzed: true,
        blunders,
        mistakes,
      };
      await saveGame(updated);
      setGame(updated);
      setState('ready');
    } catch {
      setState('error');
    }
  }

  const currentFen = fensRef.current[moveIndex + 1] ?? fensRef.current[0] ?? 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
  const currentMove = moveIndex >= 0 ? analysis[moveIndex] : null;

  const goTo = (idx: number) => {
    const clamped = Math.max(-1, Math.min(idx, (fensRef.current.length || 1) - 2));
    setMoveIndex(clamped);
  };

  // Count summary stats
  const blunderCount = analysis.filter((m) => m.classification === 'blunder').length;
  const mistakeCount = analysis.filter((m) => m.classification === 'mistake').length;
  const inaccuracyCount = analysis.filter((m) => m.classification === 'inaccuracy').length;

  if (state === 'loading') {
    return <View style={styles.center}><ActivityIndicator color={Colors.gold} size="large" /></View>;
  }

  if (state === 'error') {
    return (
      <View style={styles.center}>
        <Ionicons name="alert-circle-outline" size={48} color={Colors.blunder} />
        <Text style={styles.errorText}>Failed to load game.</Text>
        <TouchableOpacity onPress={() => router.back()}>
          <Text style={styles.backLink}>← Go back</Text>
        </TouchableOpacity>
      </View>
    );
  }

  if (state === 'analyzing') {
    const pct = progress.total > 0 ? Math.round((progress.current / progress.total) * 100) : 0;
    return (
      <View style={styles.center}>
        <ActivityIndicator color={Colors.gold} size="large" />
        <Text style={styles.analyzingTitle}>Analyzing with Stockfish</Text>
        <Text style={styles.analyzingDetail}>
          {progress.total > 0 ? `Position ${progress.current} / ${progress.total} (${pct}%)` : 'Starting engine…'}
        </Text>
        <View style={styles.progressOuter}>
          <View style={[styles.progressInner, { width: `${pct}%` }]} />
        </View>
        <Text style={styles.analyzingNote}>Using Lichess cloud evaluation (depth ~40)</Text>
      </View>
    );
  }

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
      {/* Header info */}
      {game && (
        <View style={styles.gameHeader}>
          <View>
            <Text style={styles.players}>
              {game.whitePlayer} <Text style={styles.vs}>vs</Text> {game.blackPlayer}
            </Text>
            <Text style={styles.opening}>{game.opening}</Text>
          </View>
          <View style={styles.resultBadge}>
            <Text style={styles.resultText}>{game.result}</Text>
          </View>
        </View>
      )}

      {/* Eval bar */}
      <View style={styles.evalBarWrapper}>
        <EvalBar
          cp={currentMove?.evalCp}
          mate={currentMove?.evalMate}
          height={20}
        />
      </View>

      {/* Board */}
      <ChessBoard
        fen={currentFen}
        flipped={flipped}
        highlights={
          currentMove
            ? { to: currentMove.san.replace(/[+#!?]/g, '').slice(-2) }
            : undefined
        }
      />

      {/* Navigation controls */}
      <View style={styles.navRow}>
        <NavBtn icon="play-skip-back" onPress={() => goTo(-1)} />
        <NavBtn icon="play-back" onPress={() => goTo(moveIndex - 1)} />
        <NavBtn icon="play-forward" onPress={() => goTo(moveIndex + 1)} />
        <NavBtn icon="play-skip-forward" onPress={() => goTo(fensRef.current.length - 2)} />
        <NavBtn
          icon={flipped ? 'sync' : 'sync-outline'}
          onPress={() => setFlipped(!flipped)}
          color={flipped ? Colors.gold : Colors.textSecondary}
        />
      </View>

      {/* Current move info */}
      {currentMove && (
        <View style={[styles.moveInfo, { borderColor: CLASSIFICATION_COLOR[currentMove.classification] + '55' }]}>
          <View style={styles.moveInfoTop}>
            <Text style={styles.moveSan}>{currentMove.san}</Text>
            <Text style={[styles.classification, { color: CLASSIFICATION_COLOR[currentMove.classification] }]}>
              {CLASSIFICATION_LABEL[currentMove.classification]}
            </Text>
          </View>
          <Text style={styles.evalText}>
            Eval: <Text style={styles.evalValue}>{evalLabel(currentMove.evalCp, currentMove.evalMate)}</Text>
          </Text>
          {currentMove.bestMoveSan && currentMove.bestMoveSan !== currentMove.san && (
            <Text style={styles.bestMove}>
              Best: <Text style={styles.bestMoveSan}>{currentMove.bestMoveSan}</Text>
            </Text>
          )}
          {/* Engine lines */}
          {currentMove.engineLines && currentMove.engineLines.length > 0 && (
            <View style={styles.engineLines}>
              <Text style={styles.engineLinesLabel}>Engine lines</Text>
              {currentMove.engineLines.map((line, i) => (
                <Text key={i} style={styles.engineLine} numberOfLines={1}>
                  {i + 1}. {line}
                </Text>
              ))}
            </View>
          )}
        </View>
      )}

      {/* Summary stats */}
      {analysis.length > 0 && (
        <View style={styles.summaryRow}>
          <SummaryChip label="Blunders" count={blunderCount} color={Colors.blunder} />
          <SummaryChip label="Mistakes" count={mistakeCount} color={Colors.mistake} />
          <SummaryChip label="Inaccuracies" count={inaccuracyCount} color={Colors.inaccuracy} />
        </View>
      )}

      {/* Move list */}
      {analysis.length > 0 && (
        <View style={styles.moveListCard}>
          <MoveList
            moves={analysis}
            currentIndex={moveIndex}
            onSelectMove={setMoveIndex}
          />
        </View>
      )}
    </ScrollView>
  );
}

function NavBtn({
  icon, onPress, color,
}: {
  icon: React.ComponentProps<typeof Ionicons>['name'];
  onPress: () => void;
  color?: string;
}) {
  return (
    <TouchableOpacity style={styles.navBtn} onPress={onPress} activeOpacity={0.7}>
      <Ionicons name={icon} size={22} color={color ?? Colors.textSecondary} />
    </TouchableOpacity>
  );
}

function SummaryChip({ label, count, color }: { label: string; count: number; color: string }) {
  return (
    <View style={[styles.chip, { borderColor: color + '55' }]}>
      <Text style={[styles.chipCount, { color }]}>{count}</Text>
      <Text style={styles.chipLabel}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: Colors.bg },
  content: { paddingBottom: 48, gap: Spacing.md },
  center: {
    flex: 1, justifyContent: 'center', alignItems: 'center',
    backgroundColor: Colors.bg, padding: Spacing.xl, gap: Spacing.md,
  },
  errorText: { ...Typography.subtitle, color: Colors.blunder },
  backLink: { ...Typography.body, color: Colors.gold },

  analyzingTitle: { ...Typography.subtitle, color: Colors.textPrimary },
  analyzingDetail: { ...Typography.body, color: Colors.textSecondary },
  analyzingNote: { ...Typography.caption, color: Colors.textMuted, textAlign: 'center' },
  progressOuter: { width: '80%', height: 4, backgroundColor: Colors.cardBorder, borderRadius: 2, overflow: 'hidden' },
  progressInner: { height: '100%', backgroundColor: Colors.gold },

  gameHeader: {
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center',
    paddingHorizontal: Spacing.md, paddingTop: Spacing.sm,
  },
  players: { ...Typography.subtitle, color: Colors.textPrimary },
  vs: { color: Colors.textMuted, fontWeight: '400', fontStyle: 'italic' },
  opening: { ...Typography.caption, color: Colors.gold, marginTop: 2 },
  resultBadge: {
    borderWidth: 1, borderColor: Colors.gold + '55',
    borderRadius: Radius.sm, paddingHorizontal: 10, paddingVertical: 4,
  },
  resultText: { ...Typography.body, color: Colors.gold, fontWeight: '700' },

  evalBarWrapper: { paddingHorizontal: Spacing.md },

  navRow: {
    flexDirection: 'row', justifyContent: 'center', alignItems: 'center',
    gap: Spacing.sm, paddingHorizontal: Spacing.md,
  },
  navBtn: {
    width: 48, height: 48, borderRadius: 24,
    backgroundColor: Colors.card, justifyContent: 'center', alignItems: 'center',
    borderWidth: 1, borderColor: Colors.cardBorder,
  },

  moveInfo: {
    marginHorizontal: Spacing.md, backgroundColor: Colors.card,
    borderRadius: Radius.md, padding: Spacing.md,
    borderWidth: 1, gap: 6,
  },
  moveInfoTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  moveSan: { ...Typography.title, fontSize: 28, color: Colors.textPrimary, fontFamily: 'monospace' },
  classification: { ...Typography.subtitle, fontSize: 14, fontWeight: '700' },
  evalText: { ...Typography.caption, color: Colors.textSecondary },
  evalValue: { color: Colors.gold, fontWeight: '700' },
  bestMove: { ...Typography.caption, color: Colors.textSecondary },
  bestMoveSan: { color: Colors.brilliant, fontWeight: '700', fontFamily: 'monospace' },
  engineLines: { marginTop: 4, gap: 2 },
  engineLinesLabel: { ...Typography.tiny, color: Colors.textMuted, textTransform: 'uppercase', letterSpacing: 0.5, marginBottom: 2 },
  engineLine: { ...Typography.tiny, color: Colors.textSecondary, fontFamily: 'monospace', lineHeight: 18 },

  summaryRow: {
    flexDirection: 'row', gap: Spacing.sm, paddingHorizontal: Spacing.md,
  },
  chip: {
    flex: 1, borderWidth: 1, borderRadius: Radius.md,
    backgroundColor: Colors.card, padding: Spacing.sm,
    alignItems: 'center', gap: 2,
  },
  chipCount: { ...Typography.subtitle, fontSize: 20 },
  chipLabel: { ...Typography.tiny, color: Colors.textMuted, textAlign: 'center' },

  moveListCard: {
    marginHorizontal: Spacing.md, backgroundColor: Colors.card,
    borderRadius: Radius.md, borderWidth: 1, borderColor: Colors.cardBorder,
    paddingVertical: Spacing.md,
  },
});
