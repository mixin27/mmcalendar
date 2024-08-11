import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mmcalendar/src/shared/shared.dart';
import 'package:url_launcher/url_launcher.dart';

@RoutePage()
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: Markdown(
        data: privacyPolicyMarkdown,
        onTapLink: (text, href, title) async {
          if (href == null) return;
          final url = Uri.parse(href);
          if (!await launchUrl(url)) {
            throw Exception('Could not launch $url');
          }
        },
      ),
    );
  }
}
