import 'package:shared_core/shared_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../../di/views_injection.dart';
import '../bloc/views_bloc.dart';
import '../bloc/views_event.dart';

class ViewsSelectorPage extends StatefulWidget {
  const ViewsSelectorPage({super.key});

  @override
  State<ViewsSelectorPage> createState() => _ViewsSelectorPageState();
}

class _ViewsSelectorPageState extends State<ViewsSelectorPage> {
  final AnalyticsPort _analyticsService = getIt<AnalyticsPort>();
  @override
  void initState() {
    super.initState();
    // Log screen view when page loads
    _analyticsService.logScreenView(
      screenName: 'view_selector',
      screenClass: 'ViewsSelectorPage',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar.large(
            expandedHeight: 140,
            pinned: true,
            // backgroundColor: context.colorScheme.tertiaryContainer,
            // foregroundColor: context.colorScheme.onTertiaryContainer,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Calendar Views',
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
                        alpha: 0.8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Intro Card
                _IntroCard(),
                const SizedBox(height: 24),

                // Year View Card
                _ViewCard(
                  icon: Icons.calendar_view_month,
                  title: AppLocalizations.of(context)?.year_view ?? 'Year View',
                  description: 'Browse all 12 months at once',
                  details:
                      'Perfect for planning ahead and seeing the big picture',
                  color: Colors.blue,
                  gradient: [Colors.blue.shade400, Colors.blue.shade600],
                  onTap: () {
                    context.read<ViewsBloc>().add(
                      LoadYearView(DateTime.now().year),
                    );
                    context.go('/views/year');
                  },
                ),

                const SizedBox(height: 16),

                // Week View Card
                _ViewCard(
                  icon: Icons.calendar_view_week,
                  title: AppLocalizations.of(context)?.week_view ?? 'Week View',
                  description: 'See a detailed 7-day view',
                  details: 'Ideal for weekly planning and tracking',
                  color: Colors.green,
                  gradient: [Colors.green.shade400, Colors.green.shade600],
                  onTap: () {
                    context.read<ViewsBloc>().add(LoadWeekView(DateTime.now()));
                    context.go('/views/week');
                  },
                ),

                const SizedBox(height: 16),

                // Day View Card
                _ViewCard(
                  icon: Icons.calendar_today,
                  title: AppLocalizations.of(context)?.day_view ?? 'Day View',
                  description: 'Comprehensive single-day information',
                  details: 'All details for holidays, astrology, and more',
                  color: Colors.orange,
                  gradient: [Colors.orange.shade400, Colors.orange.shade600],
                  onTap: () {
                    context.read<ViewsBloc>().add(LoadDayView(DateTime.now()));
                    context.go('/views/day');
                  },
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Intro Card explaining the purpose
class _IntroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.view_module,
                color: colorScheme.onPrimaryContainer,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)?.choose_your_view ??
                        'Choose Your View',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select how you want to explore the calendar',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enhanced View Card with gradient and better visual hierarchy
class _ViewCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final String details;
  final Color color;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ViewCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.details,
    required this.color,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_ViewCard> createState() => _ViewCardState();
}

class _ViewCardState extends State<_ViewCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        elevation: _isPressed ? 1 : 3,
        shadowColor: widget.color.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) {
            setState(() => _isPressed = true);
            _controller.forward();
          },
          onTapUp: (_) {
            setState(() => _isPressed = false);
            _controller.reverse();
          },
          onTapCancel: () {
            setState(() => _isPressed = false);
            _controller.reverse();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.color.withValues(alpha: 0.05),
                  widget.color.withValues(alpha: 0.02),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Icon with gradient background
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.gradient,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, size: 40, color: Colors.white),
                  ),
                  const SizedBox(width: 20),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.details,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 20,
                      color: widget.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
