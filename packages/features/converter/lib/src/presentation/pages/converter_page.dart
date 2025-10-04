import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../widgets/date_arithmetic_card.dart';
import '../widgets/date_calculator_card.dart';
import '../widgets/date_converter_card.dart';
import '../widgets/moon_phase_finder_card.dart';

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar.large(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Date Converter & Tools',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.colorScheme.primaryContainer,
                      context.colorScheme.primaryContainer.withValues(
                        alpha: 0.7,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: colorScheme.surface,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurface.withValues(
                    alpha: 0.6,
                  ),
                  indicatorColor: colorScheme.primary,
                  indicatorWeight: 3,
                  dividerHeight: 0,
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sync_alt, size: 20),
                          SizedBox(width: 8),
                          Text('Convert'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calculate, size: 20),
                          SizedBox(width: 8),
                          Text('Calculate'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_circle_outline, size: 20),
                          SizedBox(width: 8),
                          Text('Arithmetic'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.brightness_3, size: 20),
                          SizedBox(width: 8),
                          Text('Moon Phase'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: const [
            DateConverterCard(),
            DateCalculatorCard(),
            DateArithmeticCard(),
            MoonPhaseFinderCard(),
          ],
        ),
      ),
      // body: SingleChildScrollView(
      //   padding: const EdgeInsets.all(16.0),
      //   child: Column(
      //     crossAxisAlignment: CrossAxisAlignment.stretch,
      //     children: [
      //       // Date Converter Card
      //       DateConverterCard(),
      //       const SizedBox(height: 16),

      //       // Date Calculator Card
      //       DateCalculatorCard(),
      //       const SizedBox(height: 16),

      //       // Date Arithmetic Card
      //       DateArithmeticCard(),
      //       const SizedBox(height: 16),

      //       // Moon Phase Finder Card
      //       MoonPhaseFinderCard(),
      //       const SizedBox(height: 16),
      //     ],
      //   ),
      // ),
    );
  }
}
