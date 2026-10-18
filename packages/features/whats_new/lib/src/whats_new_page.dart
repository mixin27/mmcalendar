import 'package:flutter/material.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import 'whats_new_content.dart';
import 'whats_new_sheet.dart';
import 'whats_new_store.dart';

/// Settings › About › What's new: every release, newest first, so nothing
/// missed is lost.
class WhatsNewPage extends StatelessWidget {
  const WhatsNewPage({
    super.key,
    required this.releases,
    required this.currentVersion,
    required this.onOpen,
  });

  final List<WhatsNewRelease> releases;
  final String currentVersion;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppPage(
      title: l10n.whatsNewTitle,
      previousTitle: l10n.about,
      children: [
        for (final r in releases)
          AppGroup(
            label: WhatsNewStore.compareVersions(r.version, currentVersion) == 0
                ? l10n.whatsNewThisUpdate(displayVersion(r.version))
                : l10n.whatsNewVersion(displayVersion(r.version)),
            children: [
              for (final item in r.items)
                AppRow(
                  key: ValueKey('whats-new-${item.id}'),
                  icon: item.icon,
                  iconColor: item.color,
                  title: item.title(l10n),
                  subtitle: item.body(l10n),
                  chevron: item.route != null,
                  onTap: item.route == null ? null : () => onOpen(item.route!),
                ),
            ],
          ),
      ],
    );
  }
}
