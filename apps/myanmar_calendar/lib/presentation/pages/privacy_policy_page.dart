import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  final String title;
  final String message;

  const PrivacyPolicyPage({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: MarkdownRender(data: AppConstants.privacyPolicyMarkdown),
    );
  }
}
