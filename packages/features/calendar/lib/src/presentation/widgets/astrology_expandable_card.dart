import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';

class AstrologyExpandableCard extends StatefulWidget {
  final CompleteDate dateInfo;
  final bool isExpanded;
  final VoidCallback onToggle;

  const AstrologyExpandableCard({
    super.key,
    required this.dateInfo,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  State<AstrologyExpandableCard> createState() =>
      _AstrologyExpandableCardState();
}

class _AstrologyExpandableCardState extends State<AstrologyExpandableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _iconRotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _iconRotation = Tween<double>(begin: 0, end: 0.5).animate(_controller);

    if (widget.isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AstrologyExpandableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      widget.isExpanded ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.colorScheme.outlineVariant, width: 1),
      ),
      child: Column(
        children: [
          // Header
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onToggle,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.stars_rounded,
                        color: context.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Astrological Information',
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!widget.isExpanded)
                            Text(
                              'Tap to view details',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    RotationTransition(
                      turns: _iconRotation,
                      child: Icon(
                        Icons.expand_more,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Expandable content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: FadeTransition(
              opacity: _expandAnimation,
              child: Column(
                children: [
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildAstroContent(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAstroContent() {
    final astroItems = _getAstroItems();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...astroItems.map(
          (item) =>
              _buildAstroItem(item.label, item.value, item.icon, item.color),
        ),

        // Special days
        if (widget.dateInfo.astrologicalDays.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Special Days',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.dateInfo.astrologicalDays.map((day) {
              return Chip(
                label: Text(day),
                labelStyle: context.textTheme.bodySmall,
                backgroundColor: context.colorScheme.secondaryContainer,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildAstroItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_AstroItem> _getAstroItems() {
    final items = <_AstroItem>[];

    if (widget.dateInfo.isSabbath) {
      items.add(
        _AstroItem('Sabbath', 'Sabbath Day', Icons.brightness_2, Colors.orange),
      );
    }
    if (widget.dateInfo.yatyaza.isNotEmpty) {
      items.add(
        _AstroItem(
          'Yatyaza',
          widget.dateInfo.yatyaza,
          Icons.warning_amber,
          Colors.red,
        ),
      );
    }
    if (widget.dateInfo.pyathada.isNotEmpty) {
      items.add(
        _AstroItem(
          'Pyathada',
          widget.dateInfo.pyathada,
          Icons.info_outline,
          Colors.blue,
        ),
      );
    }
    if (widget.dateInfo.nagahle.isNotEmpty) {
      items.add(
        _AstroItem(
          'Nagahle',
          widget.dateInfo.nagahle,
          Icons.explore,
          Colors.green,
        ),
      );
    }
    if (widget.dateInfo.mahabote.isNotEmpty) {
      items.add(
        _AstroItem(
          'Mahabote',
          widget.dateInfo.mahabote,
          Icons.star,
          Colors.purple,
        ),
      );
    }
    if (widget.dateInfo.yearName.isNotEmpty) {
      items.add(
        _AstroItem(
          'Year',
          widget.dateInfo.yearName,
          Icons.calendar_today,
          Colors.teal,
        ),
      );
    }

    return items;
  }
}

class _AstroItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _AstroItem(this.label, this.value, this.icon, this.color);
}
