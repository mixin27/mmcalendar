import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../../di/converter_injection.dart';
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
  final AnalyticsPort _analyticsService = getIt<AnalyticsPort>();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Log screen view when page loads
    _analyticsService.logScreenView(
      screenName: 'converter',
      screenClass: 'ConverterPage',
    );

    _analyticsService.logScreenView(
      screenName: 'date_converter',
      screenClass: 'DateConverterCard',
    );

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
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            title: const Text(
              'Date Converter & Tools',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            flexibleSpace: FlexibleSpaceBar(
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
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sync_alt, size: 20),
                          SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)?.convert ?? 'Convert',
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calculate, size: 20),
                          SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)?.calculate ??
                                'Calculate',
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_circle_outline, size: 20),
                          SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)?.arithmetic ??
                                'Arithmetic',
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.brightness_3, size: 20),
                          SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)?.moon_phase ??
                                'Moon Phase',
                          ),
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
    );
  }
}
