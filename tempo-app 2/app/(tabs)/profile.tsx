import React, { useCallback, useState } from 'react';
import { View, Text, ScrollView, StyleSheet, TouchableOpacity, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useFocusEffect } from '@react-navigation/native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Colors, Spacing, Radius, Typography } from '../../constants/theme';
import { loadGames } from '../../services/storage';
import { SavedGame } from '../../constants/types';

export default function ProfileScreen() {
  const [games, setGames] = useState<SavedGame[]>([]);

  useFocusEffect(useCallback(() => {
    loadGames().then(setGames);
  }, []));

  const analyzedGames = games.filter((g) => g.analyzed);
  const totalBlunders = games.reduce((s, g) => s + (g.blunders ?? 0), 0);
  const totalMistakes = games.reduce((s, g) => s + (g.mistakes ?? 0), 0);
  const avgBlunders = analyzedGames.length
    ? (totalBlunders / analyzedGames.length).toFixed(1)
    : '—';

  const clearData = () => {
    Alert.alert('Clear All Data', 'Delete all games? This cannot be undone.', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Delete All', style: 'destructive',
        onPress: async () => {
          await AsyncStorage.clear();
          setGames([]);
        },
      },
    ]);
  };

  return (
    <ScrollView style={styles.screen} contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
      {/* Avatar */}
      <View style={styles.avatarSection}>
        <View style={styles.avatar}>
          <Text style={styles.avatarPiece}>♚</Text>
        </View>
        <Text style={styles.username}>Chess Player</Text>
        <Text style={styles.subtitle}>Tempo Member</Text>
      </View>

      {/* Stats grid */}
      <View style={styles.statsGrid}>
        <StatCell label="Games" value={games.length.toString()} icon="library-outline" />
        <StatCell label="Analyzed" value={analyzedGames.length.toString()} icon="analytics-outline" />
        <StatCell label="Blunders" value={totalBlunders.toString()} icon="alert-circle-outline" color={Colors.blunder} />
        <StatCell label="Mistakes" value={totalMistakes.toString()} icon="warning-outline" color={Colors.mistake} />
        <StatCell label="Avg Blunders" value={avgBlunders} icon="trending-down-outline" color={Colors.mistake} />
        <StatCell label="Inaccuracies" value="—" icon="remove-circle-outline" color={Colors.inaccuracy} />
      </View>

      {/* Settings */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Settings</Text>
        <SettingRow icon="moon-outline" label="Dark Mode" value="Always On" />
        <SettingRow icon="server-outline" label="Analysis Engine" value="Lichess Cloud" />
        <SettingRow icon="language-outline" label="Notation" value="Standard (SAN)" />
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>About</Text>
        <SettingRow icon="information-circle-outline" label="Version" value="1.0.0" />
        <SettingRow icon="code-slash-outline" label="Engine" value="Stockfish via Lichess" />
      </View>

      <TouchableOpacity style={styles.dangerBtn} onPress={clearData}>
        <Ionicons name="trash-outline" size={18} color={Colors.blunder} />
        <Text style={styles.dangerText}>Clear All Data</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

function StatCell({ label, value, icon, color = Colors.gold }: {
  label: string; value: string; icon: React.ComponentProps<typeof Ionicons>['name']; color?: string;
}) {
  return (
    <View style={styles.statCell}>
      <Ionicons name={icon} size={20} color={color} />
      <Text style={[styles.statValue, { color }]}>{value}</Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  );
}

function SettingRow({ icon, label, value }: {
  icon: React.ComponentProps<typeof Ionicons>['name']; label: string; value: string;
}) {
  return (
    <View style={styles.settingRow}>
      <Ionicons name={icon} size={18} color={Colors.textSecondary} />
      <Text style={styles.settingLabel}>{label}</Text>
      <Text style={styles.settingValue}>{value}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: Colors.bg },
  content: { paddingBottom: 48 },

  avatarSection: { alignItems: 'center', paddingVertical: Spacing.xl },
  avatar: {
    width: 80, height: 80, borderRadius: 40,
    backgroundColor: Colors.card,
    borderWidth: 2, borderColor: Colors.gold + '66',
    justifyContent: 'center', alignItems: 'center',
    marginBottom: Spacing.sm,
  },
  avatarPiece: { fontSize: 38 },
  username: { ...Typography.subtitle, color: Colors.textPrimary },
  subtitle: { ...Typography.caption, color: Colors.textMuted, marginTop: 2 },

  statsGrid: {
    flexDirection: 'row', flexWrap: 'wrap',
    marginHorizontal: Spacing.md, gap: Spacing.sm,
    marginBottom: Spacing.lg,
  },
  statCell: {
    width: '30.5%', backgroundColor: Colors.card,
    borderRadius: Radius.md, borderWidth: 1, borderColor: Colors.cardBorder,
    padding: Spacing.md, alignItems: 'center', gap: 4,
  },
  statValue: { ...Typography.title, fontSize: 20 },
  statLabel: { ...Typography.tiny, color: Colors.textMuted, textTransform: 'uppercase', textAlign: 'center' },

  section: { marginBottom: Spacing.lg },
  sectionTitle: {
    ...Typography.caption, color: Colors.textMuted,
    textTransform: 'uppercase', letterSpacing: 1,
    paddingHorizontal: Spacing.md, marginBottom: Spacing.sm,
  },
  settingRow: {
    flexDirection: 'row', alignItems: 'center', gap: Spacing.md,
    backgroundColor: Colors.card, borderBottomWidth: 1, borderBottomColor: Colors.separator,
    paddingVertical: 14, paddingHorizontal: Spacing.md,
  },
  settingLabel: { ...Typography.body, color: Colors.textSecondary, flex: 1 },
  settingValue: { ...Typography.caption, color: Colors.textMuted },

  dangerBtn: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'center',
    gap: 8, marginHorizontal: Spacing.md,
    borderWidth: 1, borderColor: Colors.blunder + '55',
    borderRadius: Radius.md, paddingVertical: 14,
  },
  dangerText: { ...Typography.body, color: Colors.blunder, fontWeight: '600' },
});
