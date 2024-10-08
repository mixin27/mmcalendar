import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:mmcalendar/src/l10n/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

class RateMeListTile extends StatelessWidget {
  const RateMeListTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () async {
        final url = Uri.parse(
          'https://play.google.com/store/apps/details?id=dev.mixin27.mmcalendar',
        );
        if (!await launchUrl(url)) {
          throw Exception('Could not launch $url');
        }
      },
      leading: const Icon(IconlyLight.star),
      title: const Text(LocaleKeys.rate_me).tr(),
    );
  }
}
