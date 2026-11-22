import 'package:unifind/screens/sign_up_screen.dart';
import 'dart:math' as math;
import 'package:unifind/app.dart';
import 'package:unifind/widgets/campus_scaffold.dart';
import 'package:unifind/widgets/campus_navigation.dart';
import 'package:unifind/widgets/post_composer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unifind/core/theme/appearance.dart';
import 'package:unifind/widgets/loading_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unifind/screens/login_screen.dart';

void main() {
  test(
    'Interface text and control outlines retain contrast in both themes',
    () {
      double contrast(Color a, Color b) {
        final first = a.computeLuminance(), second = b.computeLuminance();
        return (math.max(first, second) + .05) /
            (math.min(first, second) + .05);
      }

      for (final brightness in Brightness.values) {
        for (final high in [false, true]) {
          final c = UniFindApp.themeFor(
            brightness,
            highContrast: high,
          ).colorScheme;
          for (final pair in [
            (c.onSurface, c.surface),
            (c.onSurfaceVariant, c.surfaceContainerHigh),
            (c.onPrimary, c.primary),
            (c.onTertiaryContainer, c.tertiaryContainer),
            (c.onSecondaryContainer, c.secondaryContainer),
          ]) {
            expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
          }
          expect(
            contrast(c.outline, c.surfaceContainerHigh),
            greaterThanOrEqualTo(3),
          );
        }
      }
    },
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appearance.value = ThemeMode.system;
  });

  testWidgets('Appearance choice survives a restart', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppearanceMenu())),
    );
    await tester.tap(find.byTooltip('Appearance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark mode'));
    await tester.pumpAndSettle();
    expect(appearance.value, ThemeMode.dark);
    appearance.value = ThemeMode.system;
    await restoreAppearance();
    expect(appearance.value, ThemeMode.dark);
  });

  testWidgets('Reduced motion stops the loading animation', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: LoadingSkeleton(posts: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Loading posts'), findsOneWidget);
  });

  testWidgets(
    'Admin navigation fits a narrow screen and selects the users tab',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      int? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            bottomNavigationBar: CampusNavigation(
              index: 0,
              onSelect: (index) => selected = index,
              messages: 2,
              alerts: 1,
              pending: 3,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Users'));
      expect(selected, 4);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Campus layout adapts when resized with large text', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    for (final size in [
      const Size(320, 640),
      const Size(800, 360),
      const Size(800, 900),
      const Size(1280, 800),
    ]) {
      tester.view.physicalSize = size;
      int? selected;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: CampusScaffold(
            appBar: AppBar(title: const Text('UniFind')),
            body: const Text('Campus feed'),
            navigation: CampusNavigation(
              index: 0,
              onSelect: (i) => selected = i,
              messages: 1,
              alerts: 2,
              pending: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byType(
          size.height >= 500 && size.width >= 720
              ? NavigationRail
              : NavigationBar,
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Users'));
      expect(selected, 4);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Account screens fit a narrow phone with enlarged text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final screen in [const LoginScreen(), const SignUpScreen()]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: UniFindApp.themeFor(Brightness.dark),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.6)),
            child: child!,
          ),
          home: screen,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Posting sheet offers announcements only to admins', (
    tester,
  ) async {
    for (final user in ['student', 'admin']) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(floatingActionButton: PostComposer(username: user)),
        ),
      );
      await tester.tap(find.text('Post'));
      await tester.pumpAndSettle();
      expect(find.text('Lost Item'), findsOneWidget);
      expect(find.text('Found Item'), findsOneWidget);
      expect(
        find.text('Announcement'),
        user == 'admin' ? findsOneWidget : findsNothing,
      );
      Navigator.of(tester.element(find.text('Lost Item'))).pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Login screen renders expected controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Log In'), findsWidgets);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
