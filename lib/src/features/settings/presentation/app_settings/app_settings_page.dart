import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:mmcalendar/src/routes/routes.dart';
import 'package:mmcalendar/src/widgets/widgets.dart';

@RoutePage()
class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const NotificationSwitchListTile(),
          const CalendarLanguageListTile(),
          const AppLanguageListTile(),
          const RateMeListTile(),
          const PrivacyPolicyListTile(),
          const AboutListTile(
            icon: Icon(IconlyLight.document),
            applicationName: 'Myanmar Calendar',
            applicationVersion: 'v1.0.0',
            applicationIcon: Icon(IconlyBroken.calendar),
            applicationLegalese: 'Copyright (c) 2024 Kyaw Zayar Tun',
            child: Text('License'),
          ),
          ListTile(
            onTap: () => context.router.push(const AboutRoute()),
            leading: const Icon(IconlyLight.info_circle),
            title: const Text('About Myanmar Calendar'),
          ),
        ],
      ),
    );
  }
}
