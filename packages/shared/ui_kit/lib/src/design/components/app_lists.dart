import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../app_tokens.dart';

/// A labelled group of rows.
///
/// Clear: an inset white group on grey with hairlines and an uppercase
/// label. Material: a rounded tonal container without dividers and an
/// accent-coloured label.
class AppGroup extends StatelessWidget {
  const AppGroup({super.key, this.label, this.footer, required this.children});

  final String? label;
  final String? footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final clear = t.isClear;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null)
          Padding(
            padding: EdgeInsets.fromLTRB(16, clear ? 0 : 4, 16, 6),
            child: Text(
              clear ? label!.toUpperCase() : label!,
              style: clear
                  ? TextStyle(
                      fontSize: 12.5,
                      letterSpacing: .4,
                      color: t.secondaryLabel,
                    )
                  : TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: t.accent,
                    ),
            ),
          ),
        Material(
          color: t.surface,
          borderRadius: BorderRadius.circular(t.groupRadius),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (i, child) in children.indexed) ...[
                if (i > 0 && clear)
                  Divider(
                    height: .5,
                    thickness: .5,
                    indent: child is AppRow && child.hasLeading ? 58 : 16,
                    color: t.separator,
                  ),
                child,
              ],
            ],
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(
              footer!,
              style: TextStyle(fontSize: 12.5, color: t.secondaryLabel),
            ),
          ),
      ],
    );
  }
}

enum AppRowTone { normal, accent, destructive }

/// One list row: optional icon, title and subtitle, then a value, a
/// control, a checkmark or a chevron.
class AppRow extends StatelessWidget {
  const AppRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.leading,
    this.value,
    this.trailing,
    this.chevron = false,
    this.selected = false,
    this.tone = AppRowTone.normal,
    this.onTap,
  });

  /// A row with a switch; tapping anywhere toggles it.
  factory AppRow.toggle({
    Key? key,
    required String title,
    String? subtitle,
    IconData? icon,
    Color? iconColor,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) => AppRow(
    key: key,
    title: title,
    subtitle: subtitle,
    icon: icon,
    iconColor: iconColor,
    trailing: AppSwitch(value: value, onChanged: onChanged),
    onTap: onChanged == null ? null : () => onChanged(!value),
  );

  final String title;
  final String? subtitle;

  /// Drawn in a coloured tile in Clear, plain in Material.
  final IconData? icon;
  final Color? iconColor;

  /// Replaces [icon] with any widget (a moon glyph, an avatar).
  final Widget? leading;
  final String? value;
  final Widget? trailing;
  final bool chevron;

  /// Shows a checkmark (single-choice lists).
  final bool selected;
  final AppRowTone tone;
  final VoidCallback? onTap;

  bool get hasLeading => icon != null || leading != null;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final clear = t.isClear;
    final titleColor = switch (tone) {
      AppRowTone.accent => t.accent,
      AppRowTone.destructive => t.holiday,
      AppRowTone.normal => t.label,
    };
    final tileColor = iconColor ?? t.accent;

    Widget? lead = leading;
    if (lead == null && icon != null) {
      lead = clear
          ? Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: tileColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: Colors.white),
            )
          : Icon(icon, size: 24, color: t.secondaryLabel);
    }

    return Semantics(
      button: onTap != null,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: clear ? 46 : 56),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: clear ? 14 : 16,
              vertical: clear ? 8 : 10,
            ),
            child: Row(
              children: [
                if (lead != null) ...[
                  SizedBox(
                    width: clear ? 30 : 24,
                    child: Center(child: lead),
                  ),
                  SizedBox(width: clear ? 14 : 18),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: clear ? 15.5 : 16,
                          fontWeight: clear ? FontWeight.w500 : FontWeight.w400,
                          color: titleColor,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: clear ? 12.5 : 14,
                            color: t.secondaryLabel,
                          ),
                        ),
                    ],
                  ),
                ),
                if (value != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      value!,
                      style: TextStyle(
                        fontSize: clear ? 15 : 14,
                        color: t.secondaryLabel,
                      ),
                    ),
                  ),
                ?trailing,
                if (selected)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(Icons.check_rounded, color: t.accent),
                  ),
                if (chevron && clear)
                  Icon(Icons.chevron_right_rounded, color: t.tertiaryLabel),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// iOS switch in Clear, Material 3 switch in Material.
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return t.isClear
        ? CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: t.success,
          )
        : Switch(value: value, onChanged: onChanged);
  }
}
