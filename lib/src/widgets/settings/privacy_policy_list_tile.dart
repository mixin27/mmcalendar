import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:mmcalendar/src/routes/routes.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyListTile extends StatelessWidget {
  const PrivacyPolicyListTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.router.push(const PrivacyPolicyRoute()),
      leading: const Icon(IconlyLight.shield_done),
      title: const Text('Privacy policy'),
      trailing: IconButton(
        onPressed: () async {
          final url = Uri.parse(
            'https://www.termsfeed.com/live/f8d439ed-1831-4fc2-98a4-954a0694400f',
          );
          if (!await launchUrl(url)) {
            throw Exception('Could not launch $url');
          }
        },
        icon: Icon(
          Icons.open_in_new_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
