import 'package:flutter/material.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart' show showAppColorPicker;

import '../../../models/calendar_studio_project_theme.dart';
import '../../../theme/calendar_studio_font_catalog.dart';
import '../../../theme/calendar_studio_theme.dart';
import '../../calendar_studio_strings.dart';
import 'studio_inspector_host.dart';

/// A titled group of inspector controls.
class StudioSection extends StatelessWidget {
  const StudioSection({
    required this.title,
    required this.children,
    this.trailing,
    super.key,
  });
  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = CalendarStudioTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: .8,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink3,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

/// A label on the left and a control on the right.
class StudioFieldRow extends StatelessWidget {
  const StudioFieldRow({required this.label, required this.child, super.key});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(width: 96, child: Text(label)),
        Expanded(
          child: Align(alignment: Alignment.centerRight, child: child),
        ),
      ],
    ),
  );
}

class StudioSwitch extends StatelessWidget {
  const StudioSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    super.key,
  });
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    visualDensity: VisualDensity.compact,
    value: value,
    onChanged: onChanged,
    title: Text(label),
    subtitle: subtitle == null ? null : Text(subtitle!),
  );
}

/// Segments without check marks, so short labels stay on one line.
class StudioSegmented<T> extends StatelessWidget {
  const StudioSegmented({
    required this.segments,
    required this.value,
    required this.onChanged,
    super.key,
  });
  final List<(T, String?, IconData?)> segments;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<T>(
    showSelectedIcon: false,
    style: const ButtonStyle(visualDensity: VisualDensity.compact),
    segments: [
      for (final (value, label, icon) in segments)
        ButtonSegment(
          value: value,
          label: label == null ? null : Text(label),
          icon: icon == null ? null : Icon(icon),
          tooltip: label == null ? '$value' : null,
        ),
    ],
    selected: {value},
    onSelectionChanged: (values) => onChanged(values.first),
  );
}

/// − value + with the value typeable. Each change is its own undo step.
class StudioStepper extends StatefulWidget {
  const StudioStepper({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 9999,
    this.step = 1,
    this.decimals = 0,
    this.unit,
    super.key,
  });
  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final int decimals;
  final String? unit;
  final ValueChanged<double> onChanged;

  @override
  State<StudioStepper> createState() => _StudioStepperState();
}

class _StudioStepperState extends State<StudioStepper> {
  late final _text = TextEditingController(text: _format(widget.value));
  final _focus = FocusNode();

  String _format(double value) => value.toStringAsFixed(widget.decimals);

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _submit(_text.text);
    });
  }

  @override
  void didUpdateWidget(StudioStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus && oldWidget.value != widget.value) {
      _text.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _set(double value) {
    final next = value.clamp(widget.min, widget.max).toDouble();
    _text.text = _format(next);
    if (next != widget.value) widget.onChanged(next);
  }

  void _submit(String text) {
    final number = double.tryParse(text.trim());
    if (number == null) {
      _text.text = _format(widget.value);
      return;
    }
    _set(number);
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(widget.label)),
          IconButton(
            tooltip: '${widget.label} −',
            visualDensity: VisualDensity.compact,
            onPressed: value <= widget.min
                ? null
                : () => _set(value - widget.step),
            icon: const Icon(Icons.remove, size: 18),
          ),
          SizedBox(
            width: 72,
            child: TextField(
              key: ValueKey('studio-stepper-${widget.label}'),
              controller: _text,
              focusNode: _focus,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                isDense: true,
                suffixText: widget.unit,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 8,
                ),
              ),
              onSubmitted: _submit,
            ),
          ),
          IconButton(
            tooltip: '${widget.label} +',
            visualDensity: VisualDensity.compact,
            onPressed: value >= widget.max
                ? null
                : () => _set(value + widget.step),
            icon: const Icon(Icons.add, size: 18),
          ),
        ],
      ),
    );
  }
}

/// A text field whose whole typing session is one undo step.
class StudioTextField extends StatefulWidget {
  const StudioTextField({
    required this.host,
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
    this.hint,
    super.key,
  });
  final StudioInspectorHost host;
  final String label;
  final String value;
  final String? hint;
  final int? maxLines;
  final ValueChanged<String> onChanged;

  @override
  State<StudioTextField> createState() => _StudioTextFieldState();
}

class _StudioTextFieldState extends State<StudioTextField> {
  late final _text = TextEditingController(text: widget.value);
  final _focus = FocusNode();
  var _grouped = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_focusChanged);
  }

  void _focusChanged() {
    if (_focus.hasFocus && !_grouped) {
      _grouped = true;
      widget.host.controller.beginEditGroup();
    } else if (!_focus.hasFocus && _grouped) {
      _grouped = false;
      widget.host.controller.endEditGroup();
    }
  }

  @override
  void didUpdateWidget(StudioTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus && widget.value != _text.text) {
      _text.text = widget.value;
    }
  }

  @override
  void dispose() {
    if (_grouped) widget.host.controller.endEditGroup();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: _text,
    focusNode: _focus,
    minLines: 1,
    maxLines: widget.maxLines,
    decoration: InputDecoration(labelText: widget.label, hintText: widget.hint),
    onChanged: widget.onChanged,
  );
}

/// Theme colours by role, then colours already on the page and recent
/// picks, then a full picker.
class StudioColorField extends StatelessWidget {
  const StudioColorField({
    required this.id,
    required this.label,
    required this.value,
    required this.host,
    required this.pageColors,
    required this.onChanged,
    super.key,
  });
  final String id;
  final String label;
  final int? value;
  final StudioInspectorHost host;
  final List<int> pageColors;
  final ValueChanged<int> onChanged;

  void _pick(int color) {
    host.rememberColor(color);
    onChanged(color);
  }

  @override
  Widget build(BuildContext context) {
    final theme = host.theme;
    final extras = <int>{
      ...host.recentColors,
      ...pageColors,
    }.where((c) => !theme.colors.containsValue(c)).take(8).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final role in CalendarStudioProjectTheme.roles)
                _SwatchButton(
                  key: ValueKey('studio-color-$id-$role'),
                  color: theme.color(role),
                  tooltip: CalendarStudioProjectTheme.roleLabels[role] ?? role,
                  selected: value == theme.color(role),
                  onTap: () => _pick(theme.color(role)),
                ),
              if (extras.isNotEmpty)
                Container(
                  width: 1,
                  height: 22,
                  color: CalendarStudioTokens.of(context).line,
                ),
              for (final color in extras)
                _SwatchButton(
                  color: color,
                  tooltip: _hex(color),
                  selected: value == color,
                  onTap: () => _pick(color),
                ),
              IconButton(
                key: ValueKey('studio-color-$id-custom'),
                tooltip: StudioStrings.moreColours,
                visualDensity: VisualDensity.compact,
                onPressed: () async {
                  final picked = await showAppColorPicker(
                    context: context,
                    title: label,
                    initial: Color(value ?? theme.color('ink')),
                    doneLabel: 'Done',
                  );
                  if (picked != null) _pick(picked.toARGB32());
                },
                icon: const Icon(Icons.colorize_outlined, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _hex(int color) =>
      '#${(color & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

class _SwatchButton extends StatelessWidget {
  const _SwatchButton({
    required this.color,
    required this.tooltip,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final int color;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = CalendarStudioTokens.of(context);
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 18,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Color(color),
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? tokens.primary : tokens.line,
              width: selected ? 3 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the font in itself; opens a list of Studio's fonts that marks
/// which have Myanmar letters.
class StudioFontField extends StatelessWidget {
  const StudioFontField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  static const _myanmarSans = 'Noto Sans Myanmar';

  static List<(String, bool)> get families => [
    (_myanmarSans, true),
    for (final font in CalendarStudioFontCatalog.fonts)
      (font.family, font.myanmar),
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: InkWell(
      key: const ValueKey('studio-font-field'),
      borderRadius: BorderRadius.circular(10),
      onTap: () => _open(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.expand_more),
          isDense: true,
        ),
        child: Text(
          value,
          style: CalendarStudioFontCatalog.style(
            family: value,
            weight: FontWeight.w500,
          ).copyWith(fontSize: 16),
        ),
      ),
    ),
  );

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .7,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final (family, myanmar) in families)
                ListTile(
                  key: ValueKey('studio-font-$family'),
                  selected: family == value,
                  title: Text(
                    family,
                    style: CalendarStudioFontCatalog.style(
                      family: family,
                      weight: FontWeight.w500,
                    ).copyWith(fontSize: 18),
                  ),
                  subtitle: Text(
                    myanmar
                        ? 'Myanmar and Latin'
                        : 'Latin · Myanmar uses a matching Noto font',
                  ),
                  trailing: Text(
                    myanmar ? 'ကခ Aa' : 'Aa',
                    style: CalendarStudioFontCatalog.style(
                      family: family,
                      weight: FontWeight.w500,
                    ).copyWith(fontSize: 18),
                  ),
                  onTap: () => Navigator.pop(context, family),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && picked != value) onChanged(picked);
  }
}
