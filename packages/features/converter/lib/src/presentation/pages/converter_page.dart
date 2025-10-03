import 'package:flutter/material.dart';

import '../widgets/date_arithmetic_card.dart';
import '../widgets/date_calculator_card.dart';
import '../widgets/date_converter_card.dart';
import '../widgets/moon_phase_finder_card.dart';

class ConverterPage extends StatelessWidget {
  const ConverterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Date Converter & Tools'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Converter Card
            DateConverterCard(),
            const SizedBox(height: 16),

            // Date Calculator Card
            DateCalculatorCard(),
            const SizedBox(height: 16),

            // Date Arithmetic Card
            DateArithmeticCard(),
            const SizedBox(height: 16),

            // Moon Phase Finder Card
            MoonPhaseFinderCard(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
