import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Typography, Spacing, Radius } from '../constants/theme';
import { SavedGame } from '../constants/types';

interface Props {
  game: SavedGame;
  onPress: () => void;
  onDelete?: () => void;
}

function resultColor(result: SavedGame['result']): string {
  if (result === '1-0') return Colors.good;
  if (result === '0-1') return Colors.blunder;
  return Colors.textMuted;
}

function resultLabel(result: SavedGame['result']): string {
  if (result === '1-0') return 'White wins';
  if (result === '0-1') return 'Black wins';
  if (result === '1/2-1/2') return 'Draw';
  return 'Unknown';
}

export default function GameCard({ game, onPress, onDelete }: Props) {
  const color = resultColor(game.result);

  return (
    <TouchableOpacity style={styles.card} onPress={onPress} activeOpacity={0.8}>
      {/* Left accent strip */}
      <View style={[styles.accent, { backgroundColor: color }]} />

      <View style={styles.body}>
        <View style={styles.top}>
          <Text style={styles.opening} numberOfLines={1}>
            {game.opening ?? 'Unknown Opening'}
          </Text>
          {onDelete && (
            <TouchableOpacity onPress={onDelete} hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}>
              <Ionicons name="trash-outline" size={16} color={Colors.textMuted} />
            </TouchableOpacity>
          )}
        </View>

        <Text style={styles.players} numberOfLines={1}>
          {game.whitePlayer} <Text style={styles.vs}>vs</Text> {game.blackPlayer}
        </Text>

        <View style={styles.bottom}>
          <View style={[styles.resultBadge, { borderColor: color }]}>
            <Text style={[styles.resultText, { color }]}>{resultLabel(game.result)}</Text>
          </View>

          <View style={styles.stats}>
            {game.blunders > 0 && (
              <View style={styles.stat}>
                <Ionicons name="alert-circle" size={12} color={Colors.blunder} />
                <Text style={[styles.statText, { color: Colors.blunder }]}>
                  {game.blunders}
                </Text>
              </View>
            )}
            {game.mistakes > 0 && (
              <View style={styles.stat}>
                <Ionicons name="warning" size={12} color={Colors.mistake} />
                <Text style={[styles.statText, { color: Colors.mistake }]}>
                  {game.mistakes}
                </Text>
              </View>
            )}
          </View>

          <Text style={styles.date}>{game.date}</Text>
        </View>
      </View>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: {
    flexDirection: 'row',
    backgroundColor: Colors.card,
    borderRadius: Radius.md,
    borderWidth: 1,
    borderColor: Colors.cardBorder,
    marginHorizontal: Spacing.md,
    marginBottom: Spacing.sm,
    overflow: 'hidden',
  },
  accent: {
    width: 4,
  },
  body: {
    flex: 1,
    padding: Spacing.md,
    gap: 4,
  },
  top: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  opening: {
    ...Typography.subtitle,
    fontSize: 15,
    color: Colors.textPrimary,
    flex: 1,
    marginRight: 8,
  },
  players: {
    ...Typography.caption,
    color: Colors.textSecondary,
  },
  vs: {
    color: Colors.textMuted,
    fontStyle: 'italic',
  },
  bottom: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.sm,
    marginTop: 4,
  },
  resultBadge: {
    borderWidth: 1,
    borderRadius: Radius.sm,
    paddingHorizontal: 6,
    paddingVertical: 2,
  },
  resultText: {
    ...Typography.tiny,
    fontWeight: '700',
  },
  stats: {
    flexDirection: 'row',
    gap: 8,
    flex: 1,
  },
  stat: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
  },
  statText: {
    ...Typography.tiny,
    fontWeight: '700',
  },
  date: {
    ...Typography.tiny,
    color: Colors.textMuted,
  },
});
