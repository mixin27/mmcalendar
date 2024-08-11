import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

class NotificationSwitchListTile extends StatelessWidget {
  const NotificationSwitchListTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: true,
      onChanged: (value) {},
      secondary: const Icon(IconlyLight.notification),
      title: const Text('Notification'),
      subtitle: const Text('Push notifications'),
    );
  }
}
