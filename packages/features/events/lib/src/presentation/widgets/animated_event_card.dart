import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/event.dart';
import '../bloc/user_events_bloc.dart';
import '../bloc/user_events_event.dart';

class AnimatedEventCard extends StatefulWidget {
  final Event event;
  final Duration delay;

  const AnimatedEventCard({
    super.key,
    required this.event,
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedEventCard> createState() => _AnimatedEventCardState();
}

class _AnimatedEventCardState extends State<AnimatedEventCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final x = _isPressed ? 0.98 : 1.0;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: () {
            if (!widget.event.isCompleted) {
              context.push('/events/${widget.event.id}/detail');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Event marked as completed")),
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 12),
            transform: Matrix4.identity()..scaleByDouble(x, x, x, 1.0),
            child: Card(
              elevation: _isPressed ? 1 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Color(
                    widget.event.effectiveColor,
                  ).withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Color(
                          widget.event.effectiveColor,
                        ).withValues(alpha: 0.03),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      // Color indicator bar
                      Container(
                        width: 6,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(widget.event.effectiveColor),
                              Color(
                                widget.event.effectiveColor,
                              ).withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),

                      // Main content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title row with checkbox
                              Row(
                                children: [
                                  // Custom animated checkbox
                                  _AnimatedCheckbox(
                                    value: widget.event.isCompleted,
                                    color: Color(widget.event.effectiveColor),
                                    onChanged: (checked) {
                                      if (widget.event.id != null) {
                                        context.read<UserEventsBloc>().add(
                                          ToggleEventComplete(
                                            widget.event.id!,
                                            checked ?? false,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 12),

                                  // Title
                                  Expanded(
                                    child: Text(
                                      widget.event.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            decoration: widget.event.isCompleted
                                                ? TextDecoration.lineThrough
                                                : null,
                                            color: widget.event.isCompleted
                                                ? Colors.grey
                                                : null,
                                          ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  // Priority badge
                                  if (widget.event.priority ==
                                          EventPriority.high ||
                                      widget.event.priority ==
                                          EventPriority.urgent)
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color:
                                            widget.event.priority ==
                                                EventPriority.urgent
                                            ? Colors.red.withValues(alpha: 0.2)
                                            : Colors.orange.withValues(
                                                alpha: 0.2,
                                              ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.priority_high,
                                        size: 16,
                                        color:
                                            widget.event.priority ==
                                                EventPriority.urgent
                                            ? Colors.red
                                            : Colors.orange,
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Event details
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  // Time
                                  _buildInfoChip(
                                    icon: widget.event.isAllDay
                                        ? Icons.event
                                        : Icons.access_time,
                                    label: _formatEventTime(),
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),

                                  // Category
                                  _buildInfoChip(
                                    icon: _getCategoryIcon(),
                                    label: widget.event.category.name,
                                    color: Color(
                                      widget.event.category.colorCode,
                                    ),
                                  ),

                                  // Location
                                  if (widget.event.location != null &&
                                      widget.event.location!.isNotEmpty)
                                    _buildInfoChip(
                                      icon: Icons.location_on,
                                      label: widget.event.location!,
                                      color: Colors.blue,
                                    ),

                                  // Recurring
                                  if (widget.event.isRecurring)
                                    _buildInfoChip(
                                      icon: Icons.repeat,
                                      label: 'Repeats',
                                      color: Colors.purple,
                                    ),

                                  // Notifications
                                  if (widget.event.hasNotifications)
                                    _buildInfoChip(
                                      icon: Icons.notifications_active,
                                      label:
                                          '${widget.event.notifications.length}',
                                      color: Colors.amber.shade700,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatEventTime() {
    if (widget.event.isAllDay) {
      return 'All day';
    } else {
      return TimeOfDay.fromDateTime(widget.event.eventDateTime).format(context);
    }
  }

  IconData _getCategoryIcon() {
    switch (widget.event.category.iconName) {
      case 'person':
        return Icons.person;
      case 'work':
        return Icons.work;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'family_restroom':
        return Icons.family_restroom;
      case 'favorite':
        return Icons.favorite;
      default:
        return Icons.event;
    }
  }
}

class _AnimatedCheckbox extends StatefulWidget {
  final bool value;
  final Color color;
  final ValueChanged<bool?>? onChanged;

  const _AnimatedCheckbox({
    required this.value,
    required this.color,
    this.onChanged,
  });

  @override
  State<_AnimatedCheckbox> createState() => _AnimatedCheckboxState();
}

class _AnimatedCheckboxState extends State<_AnimatedCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    if (widget.value) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_AnimatedCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onChanged?.call(!widget.value);
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: widget.value ? widget.color : Colors.transparent,
            border: Border.all(
              color: widget.value ? widget.color : Colors.grey,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: widget.value
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}
