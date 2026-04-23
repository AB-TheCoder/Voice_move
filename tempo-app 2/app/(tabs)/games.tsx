import React, { useCallback, useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  RefreshControl,
  Alert,
  TouchableOpacity,
} from 'react-native';
import { router } from 'expo-router';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, Typography } from '../../constants/theme';
import { loadGames, deleteGame } from '../../services/storage';
import { SavedGame } from '../../constants/types';
import GameCard from '../../components/GameCard';

export default function GamesScreen() {
  const [games, setGames] = useState<SavedGame[]>([]);
  const [refreshing, setRefreshing] = useState(false);

  const loadData = async () => {
    setGames(await loadGames());
  };

  useFocusEffect(useCallback(() => { loadData(); }, []));

  const onRefresh = async () => {
    setRefreshing(true);
    await loadData();
    setRefreshing(false);
  };

  const handleDelete = (game: SavedGame) => {
    Alert.alert(
      'Delete Game',
      `Delete "${game.opening ?? 'this game'}"? This cannot be undone.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete', style: 'destructive',
          onPress: async () => {
            await deleteGame(game.id);
            await loadData();
          },
        },
      ]
    );
  };

  return (
    <ScrollView
      style={styles.screen}
      contentContainerStyle={styles.content}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={Colors.gold} />}
      showsVerticalScrollIndicator={false}
    >
      {games.length === 0 ? (
        <View style={styles.empty}>
          <Text style={styles.emptyIcon}>♜</Text>
          <Text style={styles.emptyTitle}>No games yet</Text>
          <Text style={styles.emptyBody}>Scan a scoresheet to get started.</Text>
          <TouchableOpacity
            style={styles.scanCta}
            onPress={() => router.push('/(tabs)/scan')}
          >
            <Ionicons name="camera-outline" size={18} color={Colors.gold} />
            <Text style={styles.scanCtaText}>Scan Scoresheet</Text>
          </TouchableOpacity>
        </View>
      ) : (
        <>
          <Text style={styles.count}>{games.length} game{games.length !== 1 ? 's' : ''}</Text>
          {games.map((game) => (
            <GameCard
              key={game.id}
              game={game}
              onPress={() => router.push({ pathname: '/analysis', params: { gameId: game.id } })}
              onDelete={() => handleDelete(game)}
            />
          ))}
        </>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: Colors.bg },
  content: { paddingTop: Spacing.md, paddingBottom: 40 },
  count: {
    ...Typography.caption,
    color: Colors.textMuted,
    textTransform: 'uppercase',
    letterSpacing: 1,
    paddingHorizontal: Spacing.md,
    marginBottom: Spacing.sm,
  },
  empty: {
    flex: 1,
    alignItems: 'center',
    paddingTop: 100,
    paddingHorizontal: Spacing.xl,
    gap: Spacing.sm,
  },
  emptyIcon: { fontSize: 56, opacity: 0.25, marginBottom: 8 },
  emptyTitle: { ...Typography.subtitle, color: Colors.textSecondary },
  emptyBody: { ...Typography.body, color: Colors.textMuted, textAlign: 'center' },
  scanCta: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginTop: Spacing.md,
    borderWidth: 1,
    borderColor: Colors.gold + '66',
    borderRadius: 99,
    paddingVertical: 10,
    paddingHorizontal: 20,
  },
  scanCtaText: { ...Typography.body, color: Colors.gold, fontWeight: '600' },
});
