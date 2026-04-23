export const Colors = {
  // Backgrounds
  bg: '#0A0A0F',
  surface: '#111118',
  card: '#17171F',
  cardBorder: '#2A2A38',

  // Gold accent — burnished, warm
  gold: '#C8A96E',
  goldDim: '#9A7A4A',
  goldBright: '#E8C88A',

  // Text
  textPrimary: '#F0EDE8',
  textSecondary: '#9A97A0',
  textMuted: '#5A5870',

  // Board
  lightSquare: '#EDD9A3',
  darkSquare: '#7B4F2E',
  boardBorder: '#C8A96E',
  highlightLight: '#F6F669AA',
  highlightDark: '#BACA2BBB',

  // Eval / Move classifications
  brilliant: '#1BACA6',
  good: '#81B64C',
  inaccuracy: '#F0C84E',
  mistake: '#E69F20',
  blunder: '#CA3431',

  // Eval bar
  evalWhite: '#F0EDE8',
  evalBlack: '#1A1A24',

  // UI
  separator: '#22222E',
  overlay: 'rgba(10, 10, 15, 0.85)',
} as const;

export const Spacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
} as const;

export const Radius = {
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  round: 999,
} as const;

export const Typography = {
  heroTitle: { fontSize: 38, fontWeight: '800' as const, letterSpacing: -1 },
  title: { fontSize: 24, fontWeight: '700' as const, letterSpacing: -0.5 },
  subtitle: { fontSize: 18, fontWeight: '600' as const },
  body: { fontSize: 15, fontWeight: '400' as const },
  caption: { fontSize: 13, fontWeight: '400' as const },
  tiny: { fontSize: 11, fontWeight: '500' as const, letterSpacing: 0.5 },
  mono: { fontSize: 14, fontFamily: 'monospace' as const },
} as const;
