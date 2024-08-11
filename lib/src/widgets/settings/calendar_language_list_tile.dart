import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

class CalendarLanguageListTile extends StatelessWidget {
  const CalendarLanguageListTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {},
      leading: const Icon(IconlyLight.calendar),
      title: const Text('Calendar Language'),
      subtitle: const Text('English, myanmar, karen ...'),
    );
  }
}
