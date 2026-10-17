import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../../di/converter_injection.dart';
import '../widgets/converter_tools.dart';

/// Converter tab: four tools behind one segmented control. Every tool stays
/// alive while hidden, so its inputs and last result survive switching.
class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

enum _Tool { convert, difference, arithmetic, moon }

class _ConverterPageState extends State<ConverterPage> {
  final AnalyticsPort _analyticsService = getIt<AnalyticsPort>();
  _Tool _tool = _Tool.convert;

  @override
  void initState() {
    super.initState();
    _analyticsService.logScreenView(
      screenName: 'converter',
      screenClass: 'ConverterPage',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppPage(
      title: l10n?.converter ?? 'Converter',
      children: [
        AppSegmented<_Tool>(
          segments: {
            _Tool.convert: l10n?.converter ?? 'Convert',
            _Tool.difference: 'Difference',
            _Tool.arithmetic: l10n?.arithmetic ?? 'Add/Sub',
            _Tool.moon: 'Moon',
          },
          value: _tool,
          onChanged: (tool) {
            _analyticsService.logScreenView(
              screenName: 'converter_${tool.name}',
              screenClass: 'ConverterPage',
            );
            setState(() => _tool = tool);
          },
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (tool, child) in const [
              (_Tool.convert, ConvertTool()),
              (_Tool.difference, DifferenceTool()),
              (_Tool.arithmetic, ArithmeticTool()),
              (_Tool.moon, MoonFinderTool()),
            ])
              Visibility(
                visible: tool == _tool,
                maintainState: true,
                child: child,
              ),
          ],
        ),
      ],
    );
  }
}
