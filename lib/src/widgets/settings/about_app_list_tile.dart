import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:mmcalendar/src/l10n/l10n.dart';
import 'package:mmcalendar/src/routes/routes.dart';

class AboutAppListTile extends StatelessWidget {
  const AboutAppListTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.router.push(const AboutRoute()),
      leading: const Icon(IconlyLight.info_circle),
      title: const Text(LocaleKeys.about_myanmar_calendar).tr(),
    );
  }
}
