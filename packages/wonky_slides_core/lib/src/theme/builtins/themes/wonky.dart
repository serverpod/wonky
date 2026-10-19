/// Built-in theme *Wonky* (default): clean, modern product style (05 §6).
library;

import 'package:wonky_fonts/wonky_fonts.dart';

import '../../model/common.dart';
import '../builtin_theme_def.dart';
import 'common.dart';

/// *Wonky*.
final BuiltInThemeDef wonkyTheme = BuiltInThemeDef(
  key: 'wonky',
  name: 'Wonky',
  version: 2,
  defaultAppearance: SlideAppearance.light,
  light: const [
    '#FFFFFF',
    '#0F172A',
    '#F1F5F9',
    '#475569',
    '#6366F1',
    '#06B6D4',
    '#10B981',
    '#F59E0B',
    '#EF4444',
    '#A855F7',
    '#4F46E5',
  ],
  dark: const [
    '#0B1020',
    '#F8FAFC',
    '#161C2E',
    '#94A3B8',
    '#818CF8',
    '#22D3EE',
    '#34D399',
    '#FBBF24',
    '#F87171',
    '#C084FC',
    '#A5B4FC',
  ],
  fonts: fonts(BundledFonts.openSans, 700, BundledFonts.openSans),
  codeLight: 'wonky-light',
  codeDark: 'wonky-dark',
  // The title layout has no decorations: Blank decks start plain (v2 dropped
  // v1's accent1 → accent6 gradient blob, T-17).
  decorations: {
    'comparison': [
      ThemeDecoration(
        name: 'cardLeft',
        rect: const SuRect(96, 248, 864, 760),
        geometry: 'roundRect',
        adjust: const {'radius': 0.042},
        fill: solid('theme:bg2'),
      ),
      ThemeDecoration(
        name: 'cardRight',
        rect: const SuRect(960, 248, 864, 760),
        geometry: 'roundRect',
        adjust: const {'radius': 0.042},
        fill: solid('theme:bg2'),
      ),
    ],
  },
);
