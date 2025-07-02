import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:mmcalendar/src/shared/shared.dart';
import 'package:url_launcher/url_launcher.dart';

@RoutePage()
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Myanmar Calendar')),
      body: GptMarkdown(
        aboutMyanmarCalendar,
        onLinkTap: (url, title) async {
          final uri = Uri.parse(url);
          if (!await launchUrl(uri)) {
            throw Exception('Could not launch $url');
          }
        },
      ),
    );
  }
}
