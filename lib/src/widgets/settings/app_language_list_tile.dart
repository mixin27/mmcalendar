import 'package:flutter/material.dart';

class AppLanguageListTile extends StatelessWidget {
  const AppLanguageListTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {},
      leading: const Icon(Icons.translate_outlined),
      title: const Text('App Language'),
      subtitle: const Text('In app language'),
    );
  }
}
