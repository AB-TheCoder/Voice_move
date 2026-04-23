import AsyncStorage from '@react-native-async-storage/async-storage';
import { SavedGame } from '../constants/types';

const GAMES_KEY = 'tempo:games';

export async function loadGames(): Promise<SavedGame[]> {
  try {
    const raw = await AsyncStorage.getItem(GAMES_KEY);
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}

export async function saveGame(game: SavedGame): Promise<void> {
  const games = await loadGames();
  const idx = games.findIndex((g) => g.id === game.id);
  if (idx >= 0) {
    games[idx] = game;
  } else {
    games.unshift(game); // newest first
  }
  await AsyncStorage.setItem(GAMES_KEY, JSON.stringify(games));
}

export async function deleteGame(id: string): Promise<void> {
  const games = await loadGames();
  await AsyncStorage.setItem(
    GAMES_KEY,
    JSON.stringify(games.filter((g) => g.id !== id))
  );
}

export async function getGame(id: string): Promise<SavedGame | null> {
  const games = await loadGames();
  return games.find((g) => g.id === id) ?? null;
}

export function generateId(): string {
  return `game_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`;
}
