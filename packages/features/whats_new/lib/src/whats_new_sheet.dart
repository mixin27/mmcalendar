import 'package:flutter/material.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import 'whats_new_content.dart';
import 'whats_new_store.dart';

/// "2.3.0" → "2.3"; other versions as they are.
String displayVersion(String version) {
  final v = version.split('+').first;
  return v.endsWith('.0') && v.split('.').length == 3
      ? v.substring(0, v.length - 2)
      : v;
}

/// The features added since the last update, one page each, with a button
/// that opens the feature. [onOpen] receives the route of a tapped "Try it",
/// [onSeeAll] opens the history.
Future<void> showWhatsNewSheet(
  BuildContext context, {
  required List<PendingWhatsNew> items,
  required String currentVersion,
  required ValueChanged<String> onOpen,
  required VoidCallback onSeeAll,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // The sheet paints itself from its own theme, so its background and
    // text always come from the same tokens.
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (context) {
      final t = context.tokens;
      return FractionallySizedBox(
        heightFactor: .82,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(t.sheetRadius),
            ),
          ),
          child: _WhatsNewSheet(
            items: items,
            currentVersion: currentVersion,
            onOpen: onOpen,
            onSeeAll: onSeeAll,
          ),
        ),
      );
    },
  );
}

class _WhatsNewSheet extends StatefulWidget {
  const _WhatsNewSheet({
    required this.items,
    required this.currentVersion,
    required this.onOpen,
    required this.onSeeAll,
  });

  final List<PendingWhatsNew> items;
  final String currentVersion;
  final ValueChanged<String> onOpen;
  final VoidCallback onSeeAll;

  @override
  State<_WhatsNewSheet> createState() => _WhatsNewSheetState();
}

class _WhatsNewSheetState extends State<_WhatsNewSheet> {
  final _pages = PageController();
  var _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == widget.items.length - 1) {
      Navigator.of(context).pop();
    } else {
      _pages.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.tokens;
    final current = widget.items[_page];
    final last = _page == widget.items.length - 1;
    final isCurrent =
        WhatsNewStore.compareVersions(current.version, widget.currentVersion) ==
        0;
    final action = current.item.action;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: t.isClear ? 36 : 32,
              height: t.isClear ? 5 : 4,
              margin: EdgeInsets.only(
                top: t.isClear ? 6 : 14,
                bottom: t.isClear ? 12 : 16,
              ),
              decoration: BoxDecoration(
                color: t.tertiaryLabel.withValues(alpha: .5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: t.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isCurrent
                      ? l10n.whatsNewBadge(displayVersion(current.version))
                      : l10n.whatsNewFromVersion(
                          displayVersion(current.version),
                        ),
                  style: TextStyle(
                    color: t.accent,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (widget.items.length > 1)
                Text(
                  l10n.whatsNewPageOf(_page + 1, widget.items.length),
                  style: TextStyle(color: t.tertiaryLabel, fontSize: 13),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: PageView.builder(
              key: const ValueKey('whats-new-pages'),
              controller: _pages,
              itemCount: widget.items.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) =>
                  _ItemPage(item: widget.items[i].item),
            ),
          ),
          if (widget.items.length > 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.items.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page ? t.accent : t.fill,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          if (action != null && current.item.route != null)
            AppButton(
              key: const ValueKey('whats-new-try'),
              label: action(l10n),
              onPressed: () {
                Navigator.of(context).pop();
                widget.onOpen(current.item.route!);
              },
            ),
          const SizedBox(height: 6),
          AppButton(
            key: const ValueKey('whats-new-next'),
            label: last ? l10n.whatsNewDone : l10n.whatsNewNext,
            kind: action == null ? AppButtonKind.primary : AppButtonKind.plain,
            onPressed: _next,
          ),
          if (last)
            TextButton(
              key: const ValueKey('whats-new-see-all'),
              onPressed: () {
                Navigator.of(context).pop();
                widget.onSeeAll();
              },
              child: Text(
                l10n.whatsNewSeeAll,
                style: TextStyle(color: t.accent),
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemPage extends StatelessWidget {
  const _ItemPage({required this.item});

  final WhatsNewItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.tokens;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WhatsNewArt(item: item, height: 170),
          const SizedBox(height: 16),
          Text(
            item.title(l10n),
            style: TextStyle(
              color: t.label,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.3,
              letterSpacing: -.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.body(l10n),
            style: TextStyle(
              color: t.secondaryLabel,
              fontSize: 15,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

/// A feature's picture: its icon on a soft panel in the feature's colour.
class WhatsNewArt extends StatelessWidget {
  const WhatsNewArt({super.key, required this.item, this.height = 170});

  final WhatsNewItem item;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final c = item.color;
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.withValues(alpha: .20), c.withValues(alpha: .06), t.fill],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -18,
            child: Icon(
              item.icon,
              size: height * .75,
              color: c.withValues(alpha: .10),
            ),
          ),
          Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: c.withValues(alpha: .35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(item.icon, size: 38, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
