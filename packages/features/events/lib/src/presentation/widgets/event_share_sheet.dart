import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:integrations_database/integrations_database.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../../domain/entities/event.dart';
import '../../domain/services/event_share.dart';

/// Shares [event]: a QR code to scan, the link, or an .ics file.
Future<void> showEventShareSheet(BuildContext context, Event event) {
  final l10n = AppLocalizations.of(context)!;
  return showAppSheet<void>(
    context: context,
    title: l10n.eventShareTitle,
    cancelLabel: l10n.close,
    useRootNavigator: true,
    builder: (_) => EventShareView(event: event),
  );
}

/// The share sheet's content.
class EventShareView extends StatelessWidget {
  const EventShareView({super.key, required this.event, this.database});

  final Event event;

  /// For the .ics file; the app database when null.
  final AppDatabase? database;

  Future<void> _shareLink(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final link = EventShare.link(event).toString();
    await SharePlus.instance.share(
      ShareParams(
        subject: event.title,
        text: '${l10n.eventShareMessage(event.title)}\n$link',
      ),
    );
  }

  Future<void> _copyLink(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(
      ClipboardData(text: EventShare.link(event).toString()),
    );
    if (context.mounted) {
      context.showToast(l10n.eventShareLinkCopied, kind: AppToastKind.success);
    }
  }

  Future<void> _shareFile(BuildContext context) async {
    final id = event.id;
    if (id == null) return;
    final db = database ?? GetIt.instance<AppDatabase>();
    final ics = await EventsIcs.forEvent(db, id);
    if (ics == null) return;
    final name = '${_fileName(event.title)}.${EventsIcs.extension}';
    final bytes = Uint8List.fromList(utf8.encode(ics));
    await SharePlus.instance.share(
      ShareParams(
        subject: event.title,
        files: [
          XFile.fromData(bytes, mimeType: EventsIcs.mimeType, name: name),
        ],
        fileNameOverrides: [name],
      ),
    );
  }

  /// A file name from [title]: letters (any script), digits and dashes.
  static String _fileName(String title) {
    final name = title
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '-')
        .replaceAll(RegExp('-+'), '-');
    final cut = name.length > 60 ? name.substring(0, 60) : name;
    return cut.isEmpty || cut == '-' ? 'event' : cut;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.tokens;
    final qr = EventShare.qrLink(event);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (qr != null) ...[
            Center(
              child: Container(
                key: const ValueKey('event-share-qr'),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  // Scanners need dark on light, in dark mode too.
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: qr.link.toString(),
                  size: 220,
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.white,
                  semanticsLabel: event.title,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              event.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: t.label,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              qr.withoutNotes
                  ? '${l10n.eventShareQrHint} ${l10n.eventShareQrNoNotes}'
                  : l10n.eventShareQrHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.secondaryLabel, fontSize: 13),
            ),
          ] else
            Text(
              l10n.eventShareTooLarge,
              key: const ValueKey('event-share-too-large'),
              textAlign: TextAlign.center,
              style: TextStyle(color: t.secondaryLabel, fontSize: 14),
            ),
          const SizedBox(height: 18),
          AppGroup(
            footer: l10n.eventShareFooter,
            children: [
              AppRow(
                key: const ValueKey('event-share-link'),
                icon: Icons.ios_share_rounded,
                iconColor: const Color(0xFF2F7CF6),
                title: l10n.eventShareLink,
                onTap: () => _shareLink(context),
              ),
              AppRow(
                key: const ValueKey('event-share-copy'),
                icon: Icons.link_rounded,
                iconColor: const Color(0xFF8E8E93),
                title: l10n.eventShareCopyLink,
                onTap: () => _copyLink(context),
              ),
              if (event.id != null)
                AppRow(
                  key: const ValueKey('event-share-file'),
                  icon: Icons.event_available_outlined,
                  iconColor: const Color(0xFFF08A1C),
                  title: l10n.eventShareFile,
                  onTap: () => _shareFile(context),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
