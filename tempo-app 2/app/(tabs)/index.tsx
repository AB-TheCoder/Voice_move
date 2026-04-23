import React, { useCallback, useEffect, useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  RefreshControl,
  Dimensions,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { useFocusEffect } from '@react-navigation/native';
import { Colors, Spacing, Radius, Typography } from '../../constants/theme';
import { loadGames } from '../../services/storage';
import { SavedGame } from '../../constants/types';
import GameCard from '../../components/GameCard';

const { width } = Dimensions.get('window');

export default function HomeScreen() {
  const [recentGames, setRecentGames] = useState<SavedGame[]>([]);
  const [refreshing, setRefreshing] = useState(false);

  const loadData = async () => {
    const games = await loadGames();
    setRecentGames(games.slice(0, 5));
  };

  useFocusEffect(
    useCallback(() => {
      loadData();
    }, [])
  );

  const onRefresh = async () => {
    setRefreshing(true);
    await loadData();
    setRefreshing(false);
  };

  const totalBlunders = recentGames.reduce((s, g) => s + (g.blunders ?? 0), 0);
  const totalMistakes = recentGames.reduce((s, g) => s + (g.mistakes ?? 0), 0);

  return (
    <ScrollView
      style={styles.screen}
      contentContainerStyle={styles.content}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={Colors.gold} />}
      showsVerticalScrollIndicator={false}
    >
      {/* Hero card */}
      <LinearGradient
        colors={['#1C1508', '#0F0C00', Colors.bg]}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={styles.hero}
      >
        <View style={styles.heroPattern}>
          <Text style={styles.patternPiece}>♟</Text>
        </View>
        <Text style={styles.heroTagline}>Ready to improve?</Text>
        <Text style={styles.heroSub}>
          Scan a scoresheet and get instant deep analysis with Stockfish.
        </Text>
        <TouchableOpacity
          style={styles.scanBtn}
          onPress={() => router.push('/(tabs)/scan')}
          activeOpacity={0.85}
        >
          <LinearGradient
            colors={[Colors.goldBright, Colors.gold, Colors.goldDim]}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
            style={styles.scanBtnGradient}
          >
            <Ionicons name="camera" size={20} color={Colors.bg} />
            <Text style={styles.scanBtnText}>Scan Scoresheet</Text>
          </LinearGradient>
        </TouchableOpacity>
      </LinearGradient>

      {/* Stats row */}
      {recentGames.length > 0 && (
        <View style={styles.statsRow}>
          <StatBubble
            icon="library"
            value={recentGames.length}
            label="Games"
            color={Colors.gold}
          />
          <StatBubble
            icon="alert-circle"
            value={totalBlunders}
            label="Blunders"
            color={Colors.blunder}
          />
          <StatBubble
            icon="warning"
            value={totalMistakes}
            label="Mistakes"
            color={Colors.mistake}
          />
        </View>
      )}

      {/* Recent games */}
      <View style={styles.section}>
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>Recent Games</Text>
          {recentGames.length > 0 && (
            <TouchableOpacity onPress={() => router.push('/(tabs)/games')}>
              <Text style={styles.seeAll}>See all</Text>
            </TouchableOpacity>
          )}
        </View>

        {recentGames.length === 0 ? (
          <View style={styles.emptyState}>
            <Text style={styles.emptyIcon}>♟</Text>
            <Text style={styles.emptyTitle}>No games yet</Text>
            <Text style={styles.emptyBody}>
              Scan your first scoresheet to start analyzing your chess.
            </Text>
          </View>
        ) : (
          recentGames.map((game) => (
            <GameCard
              key={game.id}
              game={game}
              onPress={() =>
                router.push({ pathname: '/analysis', params: { gameId: game.id } })
              }
            />
          ))
        )}
      </View>

      {/* Quick tips */}
      <View style={styles.tipsCard}>
        <Text style={styles.tipsTitle}>💡 Tips for scanning</Text>
        <Text style={styles.tipItem}>• Use good lighting — avoid shadows</Text>
        <Text style={styles.tipItem}>• Keep the scoresheet flat</Text>
        <Text style={styles.tipItem}>• Capture the full sheet in frame</Text>
      </View>
    </ScrollView>
  );
}

function StatBubble({
  icon,
  value,
  label,
  color,
}: {
  icon: React.ComponentProps<typeof Ionicons>['name'];
  value: number;
  label: string;
  color: string;
}) {
  return (
    <View style={[styles.statBubble, { borderColor: color + '44' }]}>
      <Ionicons name={icon} size={18} color={color} />
      <Text style={[styles.statValue, { color }]}>{value}</Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: Colors.bg },
  content: { paddingBottom: 40 },

  hero: {
    margin: Spacing.md,
    borderRadius: Radius.xl,
    padding: Spacing.xl,
    borderWidth: 1,
    borderColor: Colors.goldDim + '55',
    overflow: 'hidden',
    position: 'relative',
    minHeight: 220,
  },
  heroPattern: {
    position: 'absolute',
    right: 20,
    top: 10,
    opacity: 0.06,
  },
  patternPiece: {
    fontSize: 180,
    color: Colors.gold,
  },
  heroTagline: {
    ...Typography.heroTitle,
    color: Colors.textPrimary,
    marginBottom: 8,
  },
  heroSub: {
    ...Typography.body,
    color: Colors.textSecondary,
    lineHeight: 22,
    marginBottom: Spacing.lg,
    maxWidth: width * 0.65,
  },
  scanBtn: {
    borderRadius: Radius.round,
    overflow: 'hidden',
    alignSelf: 'flex-start',
  },
  scanBtnGradient: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: Spacing.lg,
    paddingVertical: 14,
    gap: 8,
  },
  scanBtnText: {
    ...Typography.subtitle,
    color: Colors.bg,
    fontWeight: '800',
  },

  statsRow: {
    flexDirection: 'row',
    gap: Spacing.sm,
    marginHorizontal: Spacing.md,
    marginBottom: Spacing.md,
  },
  statBubble: {
    flex: 1,
    backgroundColor: Colors.card,
    borderRadius: Radius.md,
    borderWidth: 1,
    padding: Spacing.md,
    alignItems: 'center',
    gap: 4,
  },
  statValue: {
    ...Typography.title,
    fontSize: 22,
  },
  statLabel: {
    ...Typography.tiny,
    color: Colors.textMuted,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },

  section: { marginBottom: Spacing.lg },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: Spacing.md,
    marginBottom: Spacing.sm,
  },
  sectionTitle: {
    ...Typography.subtitle,
    color: Colors.textPrimary,
  },
  seeAll: {
    ...Typography.caption,
    color: Colors.gold,
  },

  emptyState: {
    alignItems: 'center',
    paddingVertical: Spacing.xxl,
    paddingHorizontal: Spacing.xl,
    gap: Spacing.sm,
  },
  emptyIcon: { fontSize: 48, opacity: 0.3 },
  emptyTitle: {
    ...Typography.subtitle,
    color: Colors.textSecondary,
  },
  emptyBody: {
    ...Typography.body,
    color: Colors.textMuted,
    textAlign: 'center',
    lineHeight: 22,
  },

  tipsCard: {
    marginHorizontal: Spacing.md,
    backgroundColor: Colors.card,
    borderRadius: Radius.md,
    borderWidth: 1,
    borderColor: Colors.cardBorder,
    padding: Spacing.md,
    gap: 6,
  },
  tipsTitle: {
    ...Typography.caption,
    color: Colors.textSecondary,
    fontWeight: '600',
    marginBottom: 4,
  },
  tipItem: {
    ...Typography.caption,
    color: Colors.textMuted,
    lineHeight: 20,
  },
});
