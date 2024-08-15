import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:mmcalendar/src/l10n/l10n.dart';
import 'package:mmcalendar/src/widgets/widgets.dart';

@RoutePage()
class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    log('rebuild...');
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.settings.tr()),
      ),
      body: ListView(
        children: [
          // const NotificationSwitchListTile(),
          const ThemeModeSwitchTile(),
          const CalendarLanguageListTile(),
          const AppLanguageListTile(),
          const RateMeListTile(),
          const PrivacyPolicyListTile(),
          AboutListTile(
            icon: const Icon(IconlyLight.document),
            applicationName: LocaleKeys.myanmar_calendar.tr(),
            applicationVersion: 'v1.0.0',
            applicationIcon: const Icon(IconlyBroken.calendar),
            applicationLegalese: 'Copyright (c) 2024 Kyaw Zayar Tun',
            child: Text(LocaleKeys.license.tr()),
          ),
          const AboutAppListTile(),
        ],
      ),
    );
  }
}
