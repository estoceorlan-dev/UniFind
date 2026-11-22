import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appearance = ValueNotifier(ThemeMode.system);

Future<void> restoreAppearance() async {
  final value = (await SharedPreferences.getInstance()).getString('appearance');
  appearance.value = ThemeMode.values.firstWhere(
    (mode) => mode.name == value,
    orElse: () => ThemeMode.system,
  );
}

class AppearanceMenu extends StatelessWidget {
  const AppearanceMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ThemeMode>(
      tooltip: 'Appearance',
      initialValue: appearance.value,
      icon: const Icon(Icons.brightness_6_outlined),
      onSelected: (mode) async {
        appearance.value = mode;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('appearance', mode.name);
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: ThemeMode.system, child: Text('Use device theme')),
        PopupMenuItem(value: ThemeMode.light, child: Text('Light mode')),
        PopupMenuItem(value: ThemeMode.dark, child: Text('Dark mode')),
      ],
    );
  }
}
