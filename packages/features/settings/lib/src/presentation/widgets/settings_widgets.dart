import 'package:flutter/material.dart';

import 'leading_dot.dart';

/// Settings Section Widget
class SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }
}

/// Settings Tile Widget
class SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget leading;
  final VoidCallback onTap;

  const SettingsTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// Animated Switch Tile
class AnimatedSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final Color? iconColor;
  final bool useIcon;
  final ValueChanged<bool> onChanged;

  const AnimatedSwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.iconColor,
    this.useIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: LeadingDot(color: iconColor, icon: useIcon ? icon : null),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}

/// Enhanced Dialog Widget
class EnhancedDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const EnhancedDialog({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(icon: Icon(icon), title: Text(title), content: child);
  }
}

/// Radio Option Widget
class RadioOption<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final T value;
  final T groupValue;
  final ValueChanged<T?> onChanged;

  const RadioOption({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioGroup(
      groupValue: groupValue,
      onChanged: onChanged,
      child: RadioListTile<T>(
        secondary: Icon(icon),
        title: Text(title),
        subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
        value: value,
      ),
    );
  }
}
