import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'screens/loading_screen.dart';

class UniFindApp extends StatelessWidget {
  const UniFindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniFind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: uniFindPrimary,
        scaffoldBackgroundColor: uniFindBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: uniFindPrimary,
          foregroundColor: Colors.white,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: uniFindPrimary,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: uniFindPrimary),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: lightpurple,
        ),
      ),
      home: const LoadingScreen(),
    );
  }
}
