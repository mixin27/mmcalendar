import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';

import '../constants/app_constants.dart';

class MarkdownRender extends StatelessWidget {
  final String data;

  const MarkdownRender({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = isDark
        ? MarkdownConfig.darkConfig
        : MarkdownConfig.defaultConfig;
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: MarkdownWidget(data: data, config: config),
    );
  }
}
