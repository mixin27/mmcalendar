import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

Widget _app(
  AppStyle style,
  Widget child, {
  Brightness brightness = Brightness.light,
}) => MaterialApp(
  theme: AppTheme.build(
    style: style,
    colorScheme: brightness == Brightness.dark
        ? AppColorSchemes.modernDark
        : AppColorSchemes.modernLight,
  ),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('AppStyle.resolve', () {
    test('automatic follows the platform', () {
      expect(
        AppStyle.automatic.resolve(
          platform: TargetPlatform.android,
          isWeb: false,
        ),
        AppStyle.material,
      );
      expect(
        AppStyle.automatic.resolve(platform: TargetPlatform.iOS, isWeb: false),
        AppStyle.clear,
      );
      expect(
        AppStyle.automatic.resolve(
          platform: TargetPlatform.macOS,
          isWeb: false,
        ),
        AppStyle.clear,
      );
      expect(
        AppStyle.automatic.resolve(
          platform: TargetPlatform.windows,
          isWeb: false,
        ),
        AppStyle.material,
      );
      expect(
        AppStyle.automatic.resolve(
          platform: TargetPlatform.android,
          isWeb: true,
        ),
        AppStyle.clear,
      );
    });

    test('an explicit choice wins on every platform', () {
      for (final platform in TargetPlatform.values) {
        expect(
          AppStyle.clear.resolve(platform: platform, isWeb: false),
          AppStyle.clear,
        );
        expect(
          AppStyle.material.resolve(platform: platform, isWeb: false),
          AppStyle.material,
        );
      }
    });

    test('unknown stored names fall back to automatic', () {
      expect(AppStyle.fromName('clear'), AppStyle.clear);
      expect(AppStyle.fromName('holo'), AppStyle.automatic);
      expect(AppStyle.fromName(null), AppStyle.automatic);
    });
  });

  group('AppTheme.build', () {
    test('carries tokens for the resolved style', () {
      final clear = AppTheme.build(
        style: AppStyle.clear,
        colorScheme: AppColorSchemes.modernLight,
      );
      final tokens = clear.extension<AppTokens>()!;
      expect(tokens.isClear, isTrue);
      expect(tokens.background, const Color(0xFFF2F2F7));
      expect(clear.scaffoldBackgroundColor, tokens.background);
      expect(tokens.accent, AppColorSchemes.modernLight.primary);

      final material = AppTheme.build(
        style: AppStyle.material,
        colorScheme: AppColorSchemes.modernDark,
      );
      expect(material.extension<AppTokens>()!.isClear, isFalse);
      expect(material.brightness, Brightness.dark);
    });

    test('Clear dark is true black with raised grey groups', () {
      final tokens = AppTheme.build(
        style: AppStyle.clear,
        colorScheme: AppColorSchemes.modernDark,
      ).extension<AppTokens>()!;
      expect(tokens.background, const Color(0xFF000000));
      expect(tokens.surface, const Color(0xFF1C1C1E));
    });
  });

  group('ThemePresets.schemesFor', () {
    test('a preset gives its own light and dark schemes', () {
      final schemes = ThemePresets.schemesFor('ocean');
      expect(schemes.light.brightness, Brightness.light);
      expect(schemes.dark.brightness, Brightness.dark);
      expect(schemes.dark, ThemePresets.getPreset('ocean').darkColors);
    });

    test('custom colours build both brightnesses from the accent', () {
      const custom = CustomColors(
        seed: Color(0xFF0E6B5C),
        dark: {CustomColorSlot.surface: Color(0xFF101010)},
      );
      final schemes = ThemePresets.schemesFor('custom', custom: custom);
      expect(schemes.light.brightness, Brightness.light);
      expect(schemes.dark.brightness, Brightness.dark);
      expect(schemes.dark.surface, const Color(0xFF101010));
      expect(schemes.light.surface, isNot(const Color(0xFF101010)));
    });
  });

  group('CustomColors', () {
    test('round-trips through JSON', () {
      const colors = CustomColors(
        seed: Color(0xFF6B1F23),
        light: {CustomColorSlot.primary: Color(0xFF6B1F23)},
        dark: {CustomColorSlot.onSurface: Color(0xFFF3E8D2)},
        basePreset: 'traditional',
      );
      expect(CustomColors.fromJson(colors.toJson()), colors);
    });

    test('reads the older one-scheme format as hand-set colours', () {
      final legacy = {
        'brightness': 'light',
        'primary': 0xFF0E6B5C,
        'onPrimary': 0xFFFFFFFF,
        'surface': 0xFFF3F7F4,
      };
      final colors = CustomColors.fromJson(legacy);
      expect(colors.seed, const Color(0xFF0E6B5C));
      expect(colors.light[CustomColorSlot.surface], const Color(0xFFF3F7F4));
      expect(colors.dark, isEmpty);
      expect(colors.scheme(Brightness.light).surface, const Color(0xFFF3F7F4));
    });

    test('a new accent clears hand-set slots', () {
      const colors = CustomColors(
        seed: Color(0xFF000000),
        light: {CustomColorSlot.primary: Color(0xFF111111)},
      );
      final next = colors.withSeed(const Color(0xFF2F5BEA));
      expect(next.light, isEmpty);
      expect(next.seed, const Color(0xFF2F5BEA));
    });
  });

  group('components follow the style', () {
    testWidgets('switch, segmented control and nav bar', (tester) async {
      Widget gallery() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSwitch(value: true, onChanged: (_) {}),
          AppSegmented<int>(
            segments: const {0: 'Day', 1: 'Week'},
            value: 0,
            onChanged: (_) {},
          ),
          AppNavBar(
            destinations: const [
              AppNavDestination(
                icon: Icons.today_outlined,
                selectedIcon: Icons.today,
                label: 'Today',
              ),
              AppNavDestination(
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings,
                label: 'Settings',
              ),
            ],
            selectedIndex: 0,
            onSelected: (_) {},
          ),
        ],
      );

      await tester.pumpWidget(_app(AppStyle.clear, gallery()));
      expect(find.byType(CupertinoSwitch), findsOneWidget);
      expect(
        find.byType(CupertinoSlidingSegmentedControl<int>),
        findsOneWidget,
      );
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      await tester.pumpWidget(_app(AppStyle.material, gallery()));
      await tester.pumpAndSettle();
      expect(find.byType(Switch), findsOneWidget);
      expect(find.byType(SegmentedButton<int>), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    for (final style in [AppStyle.clear, AppStyle.material]) {
      testWidgets('${style.name} confirm resolves true only on confirm', (
        tester,
      ) async {
        late BuildContext context;
        await tester.pumpWidget(
          _app(style, Builder(builder: (c) => Text('host', key: Key('$c')))),
        );
        context = tester.element(find.text('host'));

        var answer = showAppConfirm(
          context: context,
          title: 'Delete event?',
          confirmLabel: 'Delete',
          destructive: true,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        expect(await answer, isTrue);

        answer = showAppConfirm(
          context: context,
          title: 'Delete event?',
          confirmLabel: 'Delete',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(await answer, isFalse);
      });
    }

    testWidgets('AppRow.toggle flips from anywhere on the row', (tester) async {
      var value = false;
      await tester.pumpWidget(
        _app(
          AppStyle.clear,
          StatefulBuilder(
            builder: (context, setState) => AppGroup(
              children: [
                AppRow.toggle(
                  title: 'Moon phases',
                  value: value,
                  onChanged: (v) => setState(() => value = v),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Moon phases'));
      await tester.pump();
      expect(value, isTrue);
    });
  });

  testWidgets('changing style restyles in place and keeps navigation', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    Widget app(AppStyle style) => MaterialApp(
      navigatorKey: navigatorKey,
      theme: AppTheme.build(
        style: style,
        colorScheme: AppColorSchemes.modernLight,
      ),
      home: const Scaffold(body: Text('root')),
    );

    await tester.pumpWidget(app(AppStyle.clear));
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('details')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(app(AppStyle.material));
    await tester.pumpAndSettle();
    expect(find.text('details'), findsOneWidget);
    expect(navigatorKey.currentState!.canPop(), isTrue);
  });
}
