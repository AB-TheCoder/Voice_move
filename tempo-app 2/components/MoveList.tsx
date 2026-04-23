import React from 'react';
import { View, Text, TouchableOpacity, ScrollView, StyleSheet } from 'react-native';
import { Colors, Typography, Spacing, Radius } from '../constants/theme';
import { MoveAnalysis, MoveClassification } from '../constants/types';

const CLASSIFICATION_ICONS: Record<MoveClassification, string> = {
  brilliant: '!!',
  good: '',
  inaccuracy: '?!',
  mistake: '?',
  blunder: '??',
  book: '',
  unknown: '',
};

const CLASSIFICATION_COLORS: Record<MoveClassification, string> = {
  brilliant: Colors.brilliant,
  good: Colors.good,
  inaccuracy: Colors.inaccuracy,
  mistake: Colors.mistake,
  blunder: Colors.blunder,
  book: Colors.textMuted,
  unknown: Colors.textSecondary,
};

interface Props {
  moves: MoveAnalysis[];
  currentIndex: number;
  onSelectMove: (index: number) => void;
}

export default function MoveList({ moves, currentIndex, onSelectMove }: Props) {
  // Group into pairs (white move + black move)
  const pairs: [MoveAnalysis, MoveAnalysis | null][] = [];
  for (let i = 0; i < moves.length; i += 2) {
    pairs.push([moves[i], moves[i + 1] ?? null]);
  }

  return (
    <View style={styles.container}>
      <Text style={styles.header}>Moves</Text>
      <ScrollView style={styles.scroll} showsVerticalScrollIndicator={false}>
        {pairs.map((pair, pairIdx) => {
          const moveNumber = pairIdx + 1;
          return (
            <View key={pairIdx} style={styles.pair}>
              <Text style={styles.moveNumber}>{moveNumber}.</Text>
              {pair.map((move, side) => {
                if (!move) return <View key={side} style={styles.moveCell} />;
                const idx = pairIdx * 2 + side;
                const isActive = idx === currentIndex;
                const icon = CLASSIFICATION_ICONS[move.classification];
                const color = CLASSIFICATION_COLORS[move.classification];

                return (
                  <TouchableOpacity
                    key={side}
                    style={[styles.moveCell, isActive && styles.activeMoveCell]}
                    onPress={() => onSelectMove(idx)}
                    activeOpacity={0.7}
                  >
                    <Text
                      style={[
                        styles.moveSan,
                        isActive && styles.activeSan,
                        move.classification === 'blunder' && styles.blunderSan,
                        move.classification === 'mistake' && styles.mistakeSan,
                      ]}
                    >
                      {move.san}
                    </Text>
                    {icon !== '' && (
                      <Text style={[styles.icon, { color }]}>{icon}</Text>
                    )}
                  </TouchableOpacity>
                );
              })}
            </View>
          );
        })}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    ...Typography.caption,
    color: Colors.textMuted,
    textTransform: 'uppercase',
    letterSpacing: 1,
    marginBottom: Spacing.sm,
    paddingHorizontal: Spacing.md,
  },
  scroll: {
    maxHeight: 200,
  },
  pair: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: Spacing.md,
    paddingVertical: 2,
  },
  moveNumber: {
    ...Typography.mono,
    color: Colors.textMuted,
    width: 28,
    fontSize: 12,
  },
  moveCell: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 4,
    paddingHorizontal: 6,
    borderRadius: Radius.sm,
    marginHorizontal: 2,
    minHeight: 28,
  },
  activeMoveCell: {
    backgroundColor: Colors.gold + '33',
    borderWidth: 1,
    borderColor: Colors.gold + '66',
  },
  moveSan: {
    ...Typography.mono,
    color: Colors.textPrimary,
    fontSize: 14,
  },
  activeSan: {
    color: Colors.goldBright,
    fontWeight: '700',
  },
  blunderSan: {
    color: Colors.blunder,
  },
  mistakeSan: {
    color: Colors.mistake,
  },
  icon: {
    fontSize: 11,
    fontWeight: '700',
    marginLeft: 2,
  },
});
