import 'package:flutter/material.dart';

import '../../models/calendar_studio_document.dart';
import '../../models/calendar_studio_project_theme.dart';
import '../../models/calendar_studio_types.dart';
import '../../services/calendar_studio_arrange.dart';
import '../../theme/calendar_studio_theme.dart';
import '../calendar_studio_strings.dart';

/// What the contextual bar can ask the editor to do.
class CalendarStudioBarActions {
  const CalendarStudioBarActions({
    required this.update,
    required this.editText,
    required this.openInspector,
    required this.duplicate,
    required this.delete,
    required this.arrange,
    required this.align,
    required this.distribute,
    this.applyToAllPages,
  });

  /// Replaces one block, as one undo step.
  final ValueChanged<CalendarStudioBlock> update;
  final VoidCallback editText;

  /// Opens the full inspector, on a tab when one is given.
  final void Function({int? tab}) openInspector;
  final VoidCallback duplicate;
  final VoidCallback delete;

  /// Moves the selected block forward (1) or backward (-1) in the layers.
  final ValueChanged<int> arrange;
  final ValueChanged<CalendarStudioAlign> align;
  final ValueChanged<CalendarStudioDistribute> distribute;

  /// Null on single-page projects.
  final VoidCallback? applyToAllPages;
}

/// The bar that floats over the selection: the 4–6 most-used controls for
/// the selected kind of block, then Duplicate, Delete, the inspector and a
/// menu for the rest.
class CalendarStudioContextualBar extends StatelessWidget {
  const CalendarStudioContextualBar({
    required this.selection,
    required this.theme,
    required this.actions,
    this.editingText = false,
    super.key,
  });

  /// The selected blocks; the last is the primary one.
  final List<CalendarStudioBlock> selection;
  final CalendarStudioProjectTheme theme;
  final CalendarStudioBarActions actions;
  final bool editingText;

  @override
  Widget build(BuildContext context) {
    final tokens = CalendarStudioTokens.of(context);
    final children = selection.length > 1
        ? _multi(context)
        : _single(context, selection.single);
    return Material(
      key: const ValueKey('calendar-studio-contextual-bar'),
      elevation: 6,
      color: tokens.surface,
      borderRadius: BorderRadius.circular(14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: IconButtonTheme(
          data: IconButtonThemeData(
            style: IconButton.styleFrom(
              foregroundColor: tokens.ink,
              visualDensity: VisualDensity.compact,
              iconSize: 20,
              minimumSize: const Size(36, 36),
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }

  List<Widget> _single(BuildContext context, CalendarStudioBlock block) {
    final enabled = !block.locked;
    return [
      if (enabled) ..._typeTools(context, block),
      if (enabled) const _Divider(),
      if (!editingText) ...[
        _button(
          'duplicate',
          Icons.copy_outlined,
          StudioStrings.duplicate,
          actions.duplicate,
        ),
        _button(
          'delete',
          Icons.delete_outline,
          StudioStrings.delete,
          actions.delete,
          color: CalendarStudioTokens.of(context).error,
        ),
      ],
      _button(
        'inspector',
        Icons.tune,
        StudioStrings.editItem,
        () => actions.openInspector(),
      ),
      if (!editingText) _moreMenu(block),
    ];
  }

  List<Widget> _typeTools(BuildContext context, CalendarStudioBlock block) {
    void set(String key, Object? value) =>
        actions.update(block.copyWith(style: {...block.style, key: value}));
    switch (block.type) {
      case CalendarStudioBlockType.text:
        final size = (block.style['fontSize'] as num?)?.toDouble() ?? 20;
        final align = block.style['align'] as String? ?? 'left';
        return [
          if (!editingText)
            _button(
              'edit-text',
              Icons.edit_note,
              StudioStrings.editText,
              actions.editText,
            ),
          _button(
            'smaller',
            Icons.text_decrease,
            StudioStrings.smallerText,
            size <= 6 ? null : () => set('fontSize', _step(size, -1)),
          ),
          SizedBox(
            width: 30,
            child: Text(
              '${size.round()}',
              key: const ValueKey('calendar-studio-bar-font-size'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          _button(
            'larger',
            Icons.text_increase,
            StudioStrings.largerText,
            size >= 400 ? null : () => set('fontSize', _step(size, 1)),
          ),
          _ColorButton(
            id: 'color',
            tooltip: StudioStrings.colour,
            value: block.style['color'] as int? ?? 0xFF15201D,
            theme: theme,
            onPicked: (value) => set('color', value),
            onMore: () => actions.openInspector(),
          ),
          _button(
            'align',
            switch (align) {
              'center' => Icons.format_align_center,
              'right' => Icons.format_align_right,
              _ => Icons.format_align_left,
            },
            StudioStrings.textAlignment,
            () => set('align', switch (align) {
              'left' => 'center',
              'center' => 'right',
              _ => 'left',
            }),
          ),
        ];
      case CalendarStudioBlockType.image || CalendarStudioBlockType.logo:
        final fit = block.style['imageFit'] as String? ?? 'crop';
        return [
          _button(
            'fit',
            switch (fit) {
              'fit' => Icons.fit_screen_outlined,
              'fill' => Icons.aspect_ratio,
              _ => Icons.crop,
            },
            StudioStrings.fitLabel(fit),
            () => set('imageFit', switch (fit) {
              'crop' => 'fit',
              'fit' => 'fill',
              _ => 'crop',
            }),
          ),
        ];
      case CalendarStudioBlockType.shape:
        final outline = block.style['fill'] == 'none';
        return [
          _ColorButton(
            id: 'color',
            tooltip: StudioStrings.colour,
            value: block.style['color'] as int? ?? 0xFF0E6B5C,
            theme: theme,
            onPicked: (value) => set('color', value),
            onMore: () => actions.openInspector(),
          ),
          _button(
            'outline',
            outline ? Icons.check_box_outline_blank : Icons.square,
            StudioStrings.outline,
            () => actions.update(
              block.copyWith(
                style: {
                  ...block.style,
                  'fill': outline ? null : 'none',
                  if (!outline &&
                      ((block.style['strokeWidth'] as num?) ?? 0) <= 0)
                    'strokeWidth': 2,
                },
              ),
            ),
            selected: outline,
          ),
        ];
      case CalendarStudioBlockType.decoration:
        return [
          _ColorButton(
            id: 'color',
            tooltip: StudioStrings.colour,
            value: block.style['color'] as int? ?? 0xFF15201D,
            theme: theme,
            onPicked: (value) => set('color', value),
            onMore: () => actions.openInspector(),
          ),
          _ColorButton(
            id: 'accent',
            tooltip: StudioStrings.accentColour,
            value: block.style['accent'] as int? ?? 0xFFB98A25,
            theme: theme,
            onPicked: (value) => set('accent', value),
            onMore: () => actions.openInspector(),
          ),
        ];
      case CalendarStudioBlockType.calendarGrid:
        return [
          _button(
            'days',
            Icons.event_note_outlined,
            StudioStrings.daysShown,
            () => actions.openInspector(tab: 0),
          ),
          _button(
            'grid-style',
            Icons.palette_outlined,
            StudioStrings.gridStyle,
            () => actions.openInspector(tab: 1),
          ),
          if (actions.applyToAllPages case final apply?)
            _button(
              'apply-all',
              Icons.library_add_check_outlined,
              StudioStrings.applyToAllMonths,
              apply,
            ),
        ];
      case CalendarStudioBlockType.eventList ||
          CalendarStudioBlockType.holidayLegend:
        return [
          if (actions.applyToAllPages case final apply?)
            _button(
              'apply-all',
              Icons.library_add_check_outlined,
              StudioStrings.applyToAllMonths,
              apply,
            ),
        ];
    }
  }

  List<Widget> _multi(BuildContext context) => [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        StudioStrings.selected(selection.length),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    PopupMenuButton<CalendarStudioAlign>(
      key: const ValueKey('calendar-studio-bar-align'),
      tooltip: StudioStrings.align,
      icon: const Icon(Icons.align_horizontal_left),
      onSelected: actions.align,
      itemBuilder: (context) => [
        for (final (edge, icon, label) in _alignments)
          PopupMenuItem(
            value: edge,
            child: ListTile(
              dense: true,
              leading: Icon(icon),
              title: Text(label),
            ),
          ),
      ],
    ),
    if (selection.length >= 3) ...[
      _button(
        'distribute-x',
        Icons.horizontal_distribute,
        StudioStrings.distributeHorizontally,
        () => actions.distribute(CalendarStudioDistribute.horizontal),
      ),
      _button(
        'distribute-y',
        Icons.vertical_distribute,
        StudioStrings.distributeVertically,
        () => actions.distribute(CalendarStudioDistribute.vertical),
      ),
    ],
    const _Divider(),
    _button(
      'duplicate',
      Icons.copy_outlined,
      StudioStrings.duplicate,
      actions.duplicate,
    ),
    _button(
      'delete',
      Icons.delete_outline,
      StudioStrings.delete,
      actions.delete,
      color: CalendarStudioTokens.of(context).error,
    ),
  ];

  static const _alignments = [
    (
      CalendarStudioAlign.left,
      Icons.align_horizontal_left,
      StudioStrings.alignLeft,
    ),
    (
      CalendarStudioAlign.centerX,
      Icons.align_horizontal_center,
      StudioStrings.alignCenter,
    ),
    (
      CalendarStudioAlign.right,
      Icons.align_horizontal_right,
      StudioStrings.alignRight,
    ),
    (CalendarStudioAlign.top, Icons.align_vertical_top, StudioStrings.alignTop),
    (
      CalendarStudioAlign.centerY,
      Icons.align_vertical_center,
      StudioStrings.alignMiddle,
    ),
    (
      CalendarStudioAlign.bottom,
      Icons.align_vertical_bottom,
      StudioStrings.alignBottom,
    ),
  ];

  Widget _moreMenu(CalendarStudioBlock block) => PopupMenuButton<String>(
    key: const ValueKey('calendar-studio-bar-more'),
    tooltip: StudioStrings.moreActions,
    icon: const Icon(Icons.more_horiz),
    onSelected: (value) => switch (value) {
      'lock' => actions.update(block.copyWith(locked: !block.locked)),
      'hide' => actions.update(block.copyWith(visible: !block.visible)),
      'forward' => actions.arrange(1),
      'backward' => actions.arrange(-1),
      _ => null,
    },
    itemBuilder: (context) => [
      _menuItem(
        'lock',
        block.locked ? Icons.lock_open_outlined : Icons.lock_outline,
        block.locked ? StudioStrings.unlock : StudioStrings.lock,
      ),
      _menuItem(
        'hide',
        block.visible
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined,
        block.visible ? StudioStrings.hide : StudioStrings.show,
      ),
      _menuItem('forward', Icons.flip_to_front, StudioStrings.bringForward),
      _menuItem('backward', Icons.flip_to_back, StudioStrings.sendBackward),
    ],
  );

  static PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label,
  ) => PopupMenuItem(
    value: value,
    child: ListTile(dense: true, leading: Icon(icon), title: Text(label)),
  );

  static Widget _button(
    String id,
    IconData icon,
    String tooltip,
    VoidCallback? onPressed, {
    Color? color,
    bool selected = false,
  }) => IconButton(
    key: ValueKey('calendar-studio-bar-$id'),
    tooltip: tooltip,
    color: color,
    isSelected: selected,
    onPressed: onPressed,
    icon: Icon(icon),
  );

  /// Font size steps: whole points below 24, then 2s, then 4s.
  static double _step(double size, int direction) {
    final step = size < 24 ? 1.0 : (size < 48 ? 2.0 : 4.0);
    return ((size / step).round() + direction) * step;
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 22,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    color: CalendarStudioTokens.of(context).line,
  );
}

/// A swatch that opens the theme's colours, then "More colours…".
class _ColorButton extends StatelessWidget {
  const _ColorButton({
    required this.id,
    required this.tooltip,
    required this.value,
    required this.theme,
    required this.onPicked,
    required this.onMore,
  });
  final String id;
  final String tooltip;
  final int value;
  final CalendarStudioProjectTheme theme;
  final ValueChanged<int> onPicked;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) => PopupMenuButton<int?>(
    key: ValueKey('calendar-studio-bar-$id'),
    tooltip: tooltip,
    onSelected: (picked) => picked == null ? onMore() : onPicked(picked),
    icon: _Swatch(value),
    itemBuilder: (context) => [
      for (final role in CalendarStudioProjectTheme.roles)
        PopupMenuItem<int?>(
          key: ValueKey('calendar-studio-bar-$id-$role'),
          value: theme.color(role),
          child: Row(
            children: [
              _Swatch(theme.color(role), selected: theme.color(role) == value),
              const SizedBox(width: 12),
              Text(CalendarStudioProjectTheme.roleLabels[role] ?? role),
            ],
          ),
        ),
      const PopupMenuDivider(),
      const PopupMenuItem<int?>(
        value: null,
        child: Text(StudioStrings.moreColours),
      ),
    ],
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.value, {this.selected = false});
  final int value;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokens = CalendarStudioTokens.of(context);
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Color(value),
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? tokens.primary : tokens.line,
          width: selected ? 2.5 : 1,
        ),
      ),
    );
  }
}
