import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

void main() {
  for (final style in [AppStyle.clear, AppStyle.material]) {
    testWidgets(
      '${style.name}: the extended rail lays out with a full-width header',
      (tester) async {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = const Size(1300, 800);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.build(
              style: style,
              colorScheme: AppColorSchemes.modernLight,
            ),
            home: Scaffold(
              body: Row(
                children: [
                  AppNavRail(
                    destinations: const [
                      AppNavDestination(
                        icon: Icons.home_outlined,
                        selectedIcon: Icons.home,
                        label: 'Home',
                      ),
                      AppNavDestination(
                        icon: Icons.settings_outlined,
                        selectedIcon: Icons.settings,
                        label: 'Settings',
                      ),
                    ],
                    selectedIndex: 0,
                    onSelected: (_) {},
                    extended: true,
                    header: const Row(
                      children: [
                        SizedBox(width: 40, height: 40),
                        Expanded(child: Text('Myanmar Calendar')),
                      ],
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Myanmar Calendar'), findsOneWidget);
      },
    );
  }
}
