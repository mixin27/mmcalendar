import 'package:flutter/material.dart';

import '../../models/calendar_studio_document.dart';
import '../../models/calendar_studio_project_theme.dart';
import '../../models/calendar_studio_types.dart';
import '../../templates/calendar_studio_text_styles.dart';
import '../../theme/calendar_studio_font_catalog.dart';
import '../../theme/calendar_studio_theme.dart';
import '../../widgets/calendar_studio_decorations.dart';
import '../calendar_studio_strings.dart';

/// Something the Add panel can put on the page.
class StudioAddItem {
  const StudioAddItem({
    required this.id,
    required this.label,
    required this.type,
    this.subtitle,
    this.icon,
    this.bounds,
    this.content = const {},
    this.style = const {},
    this.pick = false,
  });
  final String id;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final CalendarStudioBlockType type;
  final StudioRect? bounds;
  final Map<String, Object?> content;
  final Map<String, Object?> style;

  /// Images and logos come from the photo picker instead.
  final bool pick;
}

enum StudioAddTab { text, elements, images, calendar, recent }

/// Every item, coloured from the project theme.
abstract final class StudioAddCatalog {
  static const _shapes = [
    ('rectangle', StudioStrings.rectangle, Icons.rectangle_outlined),
    ('rounded', StudioStrings.rounded, Icons.crop_16_9_rounded),
    ('circle', StudioStrings.circle, Icons.circle_outlined),
    ('oval', StudioStrings.oval, Icons.circle_outlined),
    ('triangle', StudioStrings.triangle, Icons.change_history),
    ('diamond', StudioStrings.diamond, Icons.diamond_outlined),
    ('pentagon', StudioStrings.pentagon, Icons.pentagon_outlined),
    ('hexagon', StudioStrings.hexagon, Icons.hexagon_outlined),
    ('octagon', StudioStrings.octagon, Icons.stop_outlined),
    ('star', StudioStrings.star, Icons.star_outline),
    ('heart', StudioStrings.heart, Icons.favorite_border),
    ('arrow', StudioStrings.arrow, Icons.arrow_forward),
    ('line', StudioStrings.line, Icons.horizontal_rule),
  ];

  static const emojis = [
    '😀', '😂', '🥰', '😍', '😎', '🤩', '🥳', '😊', '🙏', '👏', '👍', '❤️', //
    '🧡', '💛', '💚', '💙', '⭐', '✨', '🔥', '🎉', '🎁', '🎂', '🏆', '💡', //
    '🌸', '🌺', '🌿', '🍀', '🌈', '🐘', '🦚', '🦋', '🐉', '🍜', '☕', '🚗', //
    '✈️', '🏠', '🏯', '🛕', '📅', '📌', '✅', '⚠️', '💬',
  ];

  static String label(String id) {
    final spaced = id.replaceAllMapped(
      RegExp('[A-Z]'),
      (m) => ' ${m[0]!.toLowerCase()}',
    );
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  static List<StudioAddItem> text(CalendarStudioProjectTheme theme) => [
    for (final preset in CalendarStudioTextStyle.all)
      StudioAddItem(
        id: 'text-${preset.id}',
        label: preset.label,
        type: CalendarStudioBlockType.text,
        bounds: StudioRect(
          left: .15,
          top: .15,
          width: .7,
          height: preset.height,
        ),
        content: {'text': preset.sample},
        style: {...preset.build(theme), 'align': 'left'},
      ),
  ];

  static StudioAddItem emoji(String emoji) => StudioAddItem(
    id: 'emoji-$emoji',
    label: emoji,
    type: CalendarStudioBlockType.text,
    bounds: const StudioRect(left: .35, top: .25, width: .3, height: .18),
    content: {'text': emoji},
    style: const {
      'fontSize': 72.0,
      'fontWeight': 400,
      'align': 'center',
      'color': 0xFF15201D,
    },
  );

  static List<StudioAddItem> shapes(CalendarStudioProjectTheme theme) => [
    for (final (id, name, icon) in _shapes)
      StudioAddItem(
        id: 'shape-$id',
        label: name,
        icon: icon,
        type: CalendarStudioBlockType.shape,
        bounds: id == 'line'
            ? const StudioRect(left: .2, top: .3, width: .6, height: .025)
            : const StudioRect(left: .25, top: .2, width: .5, height: .25),
        content: {'shape': id},
        style: {
          'color': theme.color('primary'),
          'strokeColor': theme.color('ink'),
          'strokeWidth': 0.0,
          'opacity': 1.0,
        },
      ),
  ];

  static List<StudioAddItem> decorations(CalendarStudioProjectTheme theme) => [
    for (final kind in CalendarStudioDecorations.kinds)
      StudioAddItem(
        id: 'decoration-$kind',
        label: label(kind),
        type: CalendarStudioBlockType.decoration,
        bounds: const StudioRect(left: .3, top: .2, width: .4, height: .25),
        content: {'kind': kind},
        style: {
          'color': theme.color('primary'),
          'accent': theme.color('accent'),
        },
      ),
  ];

  static const images = [
    StudioAddItem(
      id: 'image',
      label: StudioStrings.photoFromYourGallery,
      subtitle: StudioStrings.photoHint,
      icon: Icons.image_outlined,
      type: CalendarStudioBlockType.image,
      pick: true,
    ),
    StudioAddItem(
      id: 'logo',
      label: StudioStrings.logo,
      subtitle: StudioStrings.yourBrandMark,
      icon: Icons.verified_outlined,
      type: CalendarStudioBlockType.logo,
      pick: true,
    ),
  ];

  static List<StudioAddItem> calendar(
    CalendarStudioProjectTheme theme,
    CalendarStudioPage page,
  ) {
    final gridStyle = {
      'inkColor': theme.color('ink'),
      'mutedColor': theme.color('inkMuted'),
      'headerColor': theme.color('primary'),
      'holidayColor': theme.color('holiday'),
      'sabbathColor': theme.color('sabbath'),
      'lineColor': theme.color('line'),
    };
    StudioAddItem mini(int month, String label, double left) => StudioAddItem(
      id: 'mini-$label',
      label: StudioStrings.miniMonth(label),
      subtitle: StudioStrings.miniMonthHint(StudioStrings.months[month - 1]),
      icon: Icons.calendar_view_month_outlined,
      type: CalendarStudioBlockType.calendarGrid,
      bounds: StudioRect(left: left, top: .06, width: .26, height: .18),
      content: {'mini': true, 'calendarStyle': 'standard', 'month': month},
      style: gridStyle,
    );
    return [
      StudioAddItem(
        id: 'grid',
        label: StudioStrings.calendarGrid,
        subtitle: StudioStrings.calendarGridHint,
        icon: Icons.calendar_month_outlined,
        type: CalendarStudioBlockType.calendarGrid,
        bounds: const StudioRect(left: .06, top: .45, width: .88, height: .42),
        content: const {'calendarStyle': 'standard'},
        style: gridStyle,
      ),
      if (page.month > 1) mini(page.month - 1, StudioStrings.previous, .06),
      if (page.month < 12) mini(page.month + 1, StudioStrings.nextMonth, .68),
      StudioAddItem(
        id: 'events',
        label: StudioStrings.eventList,
        subtitle: StudioStrings.eventListHint,
        icon: Icons.event_note_outlined,
        type: CalendarStudioBlockType.eventList,
        bounds: const StudioRect(left: .06, top: .72, width: .5, height: .2),
        content: const {'title': 'This month'},
        style: {
          'titleColor': theme.color('primary'),
          'inkColor': theme.color('ink'),
          'mutedColor': theme.color('inkMuted'),
          'lineColor': theme.color('line'),
          'fontFamily': ?theme.bodyFont,
        },
      ),
      StudioAddItem(
        id: 'legend',
        label: StudioStrings.holidayLegend,
        subtitle: StudioStrings.legendHint,
        icon: Icons.label_outline,
        type: CalendarStudioBlockType.holidayLegend,
        bounds: const StudioRect(left: .06, top: .92, width: .88, height: .04),
        content: const {'kind': 'themed'},
        style: {
          'inkColor': theme.color('ink'),
          'mutedColor': theme.color('inkMuted'),
          'holidayColor': theme.color('holiday'),
          'sabbathColor': theme.color('sabbath'),
          'moonColor': theme.color('accent'),
          'eventColor': theme.color('primary'),
        },
      ),
    ];
  }

  /// Every item, for looking up recent ones by id.
  static List<StudioAddItem> all(
    CalendarStudioProjectTheme theme,
    CalendarStudioPage page,
  ) => [
    ...text(theme),
    ...shapes(theme),
    ...decorations(theme),
    ...images,
    ...calendar(theme, page),
  ];
}

/// Add to page: text styles, elements, images, calendar parts and what
/// was added recently. A sheet on phones, a side panel on wide screens.
class CalendarStudioAddPanel extends StatefulWidget {
  const CalendarStudioAddPanel({
    required this.theme,
    required this.page,
    required this.recent,
    required this.onAdd,
    this.initialTab = StudioAddTab.text,
    this.onClose,
    super.key,
  });
  final CalendarStudioProjectTheme theme;
  final CalendarStudioPage page;

  /// Recently added items, newest first.
  final List<StudioAddItem> recent;
  final ValueChanged<StudioAddItem> onAdd;
  final StudioAddTab initialTab;
  final VoidCallback? onClose;

  @override
  State<CalendarStudioAddPanel> createState() => _CalendarStudioAddPanelState();
}

class _CalendarStudioAddPanelState extends State<CalendarStudioAddPanel>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(
    length: StudioAddTab.values.length,
    vsync: this,
    initialIndex: widget.initialTab.index,
  );
  final _emoji = TextEditingController();

  @override
  void dispose() {
    _tabs.dispose();
    _emoji.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Material(
      key: const ValueKey('calendar-studio-add-panel'),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
            child: Row(
              children: [
                Text(
                  StudioStrings.addToPage,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                if (widget.onClose case final close?)
                  IconButton(
                    tooltip: StudioStrings.close,
                    onPressed: close,
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ),
          TabBar(
            controller: _tabs,
            // Five short tabs share the width, so none hides off-screen.
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            tabs: const [
              Tab(text: StudioStrings.text),
              Tab(text: StudioStrings.elements),
              Tab(text: StudioStrings.images),
              Tab(text: StudioStrings.calendar),
              Tab(text: StudioStrings.recent),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _textTab(theme),
                _elementsTab(theme),
                _list(StudioAddCatalog.images),
                _list(StudioAddCatalog.calendar(theme, widget.page)),
                widget.recent.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            StudioStrings.recentEmpty,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : _list(widget.recent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _textTab(CalendarStudioProjectTheme theme) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
    children: [
      for (final item in StudioAddCatalog.text(theme))
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _Tile(
            key: ValueKey('studio-add-${item.id}'),
            onTap: () => widget.onAdd(item),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item.content['text']! as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    CalendarStudioFontCatalog.style(
                      family: item.style['fontFamily'] as String?,
                      weight: FontWeight.values.firstWhere(
                        (w) => w.value == item.style['fontWeight'],
                        orElse: () => FontWeight.w400,
                      ),
                    ).copyWith(
                      fontSize: ((item.style['fontSize'] as num).toDouble())
                          .clamp(12, 30),
                      letterSpacing: (item.style['letterSpacing'] as num?)
                          ?.toDouble(),
                      color: Color(item.style['color']! as int),
                    ),
              ),
            ),
          ),
        ),
      const SizedBox(height: 12),
      Text(StudioStrings.emoji, style: Theme.of(context).textTheme.titleSmall),
      TextField(
        controller: _emoji,
        decoration: InputDecoration(
          labelText: StudioStrings.emojiField,
          suffixIcon: IconButton(
            onPressed: _addTypedEmoji,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ),
        onSubmitted: (_) => _addTypedEmoji(),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final emoji in StudioAddCatalog.emojis)
            InkWell(
              onTap: () => widget.onAdd(StudioAddCatalog.emoji(emoji)),
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),
              ),
            ),
        ],
      ),
    ],
  );

  void _addTypedEmoji() {
    final value = _emoji.text.trim();
    if (value.isEmpty) return;
    widget.onAdd(StudioAddCatalog.emoji(value));
  }

  Widget _elementsTab(CalendarStudioProjectTheme theme) {
    final tokens = CalendarStudioTokens.of(context);
    Widget grid(
      List<StudioAddItem> items,
      Widget Function(StudioAddItem) art,
    ) => GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: .9,
      children: [
        for (final item in items)
          _Tile(
            key: ValueKey('studio-add-${item.id}'),
            padding: const EdgeInsets.all(6),
            onTap: () => widget.onAdd(item),
            child: Column(
              children: [
                Expanded(child: Center(child: art(item))),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
      ],
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          StudioStrings.shapes,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        grid(
          StudioAddCatalog.shapes(theme),
          (item) =>
              Icon(item.icon, size: 30, color: Color(theme.color('primary'))),
        ),
        const SizedBox(height: 16),
        Text(
          StudioStrings.decorations,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        grid(
          StudioAddCatalog.decorations(theme),
          (item) => SizedBox.square(
            dimension: 48,
            child:
                CalendarStudioDecorations.build(
                  CalendarStudioBlock(
                    id: item.id,
                    type: item.type,
                    name: item.label,
                    bounds: const StudioRect(
                      left: 0,
                      top: 0,
                      width: 1,
                      height: 1,
                    ),
                    content: item.content,
                    style: item.style,
                  ),
                ) ??
                Icon(Icons.spa_outlined, color: tokens.gold),
          ),
        ),
      ],
    );
  }

  Widget _list(List<StudioAddItem> items) {
    final tokens = CalendarStudioTokens.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _Tile(
              key: ValueKey('studio-add-${item.id}'),
              onTap: () => widget.onAdd(item),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: tokens.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: item.icon == null
                        ? Center(child: Text(item.label.characters.first))
                        : Icon(item.icon),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (item.subtitle case final subtitle?)
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    super.key,
  });
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final tokens = CalendarStudioTokens.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: padding,
        decoration: BoxDecoration(
          color: tokens.surface2,
          borderRadius: BorderRadius.circular(14),
        ),
        child: child,
      ),
    );
  }
}
