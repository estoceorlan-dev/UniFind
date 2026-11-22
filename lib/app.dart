import 'package:flutter/material.dart';

import 'core/theme/appearance.dart';
import 'screens/loading_screen.dart';

class UniFindApp extends StatelessWidget {
  const UniFindApp({super.key});

  static ThemeData themeFor(
    Brightness brightness, {
    bool highContrast = false,
  }) {
    final dark = brightness == Brightness.dark;
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xff006b5c),
      brightness: brightness,
      contrastLevel: highContrast ? 1 : 0.45,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: colors.outlineVariant),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: dark
          ? const Color(0xff101715)
          : const Color(0xfff3f6f3),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: shape,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerHigh,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.outline),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: colors.surface,
        indicatorColor: colors.primaryContainer,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 50)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: appearance,
    builder: (_, mode, _) => MaterialApp(
      title: 'UniFind',
      debugShowCheckedModeBanner: false,
      theme: themeFor(Brightness.light),
      darkTheme: themeFor(Brightness.dark),
      highContrastTheme: themeFor(Brightness.light, highContrast: true),
      highContrastDarkTheme: themeFor(Brightness.dark, highContrast: true),
      themeMode: mode,
      home: const LoadingScreen(),
    ),
  );
}
