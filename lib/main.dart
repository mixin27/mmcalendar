import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mmcalendar/src/features/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [
          Locale('en'),
          Locale('en', 'US'),
          Locale('my')
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('en', 'US'),
        child: AppWidget(),
      ),
    ),
  );
}
