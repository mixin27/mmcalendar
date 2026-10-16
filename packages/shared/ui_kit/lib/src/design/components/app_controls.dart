import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../app_tokens.dart';

/// A small set of exclusive choices: a sliding iOS segmented control in
/// Clear, an outlined Material segmented button in Material.
class AppSegmented<T extends Object> extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
  });

  final Map<T, String> segments;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (t.isClear) {
      return SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<T>(
          groupValue: value,
          backgroundColor: t.fill,
          thumbColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF5A5A5E)
              : Colors.white,
          children: {
            for (final MapEntry(:key, value: label) in segments.entries)
              key: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: t.label,
                  ),
                ),
              ),
          },
          onValueChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<T>(
        showSelectedIcon: false,
        segments: [
          for (final MapEntry(:key, value: label) in segments.entries)
            ButtonSegment(
              value: key,
              label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ],
        selected: {value},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}

enum AppButtonKind { primary, tinted, plain, destructive }

/// Buttons in the four kinds the design uses. Clear: 50 pt, 14 pt corners.
/// Material: 48 dp pills (tonal for tinted).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.kind = AppButtonKind.primary,
    this.expand = true,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonKind kind;

  /// Full width (forms, sheets) or content width.
  final bool expand;

  /// 36–40 pt high, for rows and cards.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final height = compact
        ? (t.isClear ? 36.0 : 40.0)
        : (t.isClear ? 50.0 : 48.0);
    final shape = t.isClear
        ? RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 10 : t.controlRadius),
          )
        : const StadiumBorder();
    final (background, foreground) = switch (kind) {
      AppButtonKind.primary => (t.accent, t.onAccent),
      AppButtonKind.tinted =>
        t.isClear
            ? (t.accentSoft, t.accent)
            : (scheme.secondaryContainer, scheme.onSecondaryContainer),
      AppButtonKind.plain => (Colors.transparent, t.accent),
      AppButtonKind.destructive => (t.holidaySoft, t.holiday),
    };
    final style = FilledButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      disabledBackgroundColor: kind == AppButtonKind.plain
          ? Colors.transparent
          : t.fill,
      minimumSize: Size(expand ? double.infinity : 64, height),
      padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 20),
      shape: shape,
      elevation: 0,
      textStyle: TextStyle(
        fontSize: compact ? 14 : (t.isClear ? 16 : 15),
        fontWeight: FontWeight.w600,
      ),
    );
    final text = Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
    return icon == null
        ? FilledButton(onPressed: onPressed, style: style, child: text)
        : FilledButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: compact ? 18 : 20),
            label: text,
          );
  }
}

/// A selectable chip: a filled pill in Clear, a Material filter chip.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (!t.isClear) {
      return FilterChip(
        label: Text(label),
        avatar: icon == null ? null : Icon(icon, size: 18),
        selected: selected,
        onSelected: onSelected,
      );
    }
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? t.accent : t.fill,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => onSelected(!selected),
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: selected ? t.onAccent : t.label),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: selected ? t.onAccent : t.label,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Search input: the iOS search field in Clear, a Material search bar.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.placeholder = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String placeholder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (t.isClear) {
      return CupertinoSearchTextField(
        controller: controller,
        placeholder: placeholder,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        autofocus: autofocus,
        backgroundColor: t.fill,
        style: TextStyle(color: t.label),
      );
    }
    return SearchBar(
      controller: controller,
      hintText: placeholder,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autoFocus: autofocus,
      elevation: const WidgetStatePropertyAll(0),
      leading: const Icon(Icons.search),
    );
  }
}
