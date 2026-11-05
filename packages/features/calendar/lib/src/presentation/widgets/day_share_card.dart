import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:holidays/holidays.dart';
import 'package:myanmar_calendar_dart/myanmar_calendar_dart.dart';
import 'package:share_plus/share_plus.dart' show XFile;
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import 'astro_phrases.dart';
import 'calendar_colors.dart';

/// The shape of a shared day image.
enum DayShareShape {
  /// 1080 × 1080, for posts.
  square(Size(360, 360)),

  /// 1080 × 1920, for stories.
  story(Size(360, 640));

  const DayShareShape(this.size);

  /// The card's layout size; images are 3× this.
  final Size size;
}

/// A day as a card to share: the Western date and weekday, the Myanmar date
/// large, the moon, the holiday and Sabbath, and the day's good and caution
/// marks, signed "Myanmar Calendar".
class DayShareCard extends StatelessWidget {
  const DayShareCard({
    super.key,
    required this.date,
    this.shape = DayShareShape.square,
  });

  final DateTime date;
  final DayShareShape shape;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = context.calendarFormat;
    final language = context.calendarLanguage;
    final t = context.tokens;
    final day = DateTime(date.year, date.month, date.day);
    final complete = MyanmarCalendar.getCompleteDateFor(
      day.year,
      day.month,
      day.day,
    );
    final holidays = [
      if (l10n != null)
        for (final o in HolidayYears.of(day.year, language))
          if (o.contains(day)) o.entry.title(l10n),
    ];
    final marks = GoodDays.marks(complete);
    String marksOf(AstroTone tone) => [
      for (final m in marks)
        if (GoodDays.tone(m) == tone) AstroPhrases.mark(m, language),
    ].join(' · ');
    final good = marksOf(AstroTone.good);
    final caution = marksOf(AstroTone.caution);
    final story = shape == DayShareShape.story;
    final accent = t.accent;
    const good0 = Color(0xFF2F9E5B);

    Widget line(String text, {Color? color, double size = 13, FontWeight? w}) =>
        Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color ?? t.secondaryLabel,
            fontSize: size,
            fontWeight: w ?? FontWeight.w500,
            height: 1.35,
          ),
        );

    return SizedBox.fromSize(
      size: shape.size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(accent.withValues(alpha: .14), t.surface),
              t.surface,
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, story ? 64 : 22, 24, 18),
          child: Column(
            children: [
              line(
                '${format.weekday(day)} · ${format.dayMonth(day)} '
                '${format.westernNumber(day.year)}',
                color: t.label,
                size: story ? 17 : 14,
                w: FontWeight.w600,
              ),
              SizedBox(height: story ? 40 : 14),
              MoonGlyph(date: day, size: story ? 132 : 76),
              SizedBox(height: story ? 28 : 12),
              line(
                format.myanmar(complete.myanmar, '&y &M'),
                color: t.label,
                size: story ? 22 : 17,
                w: FontWeight.w700,
              ),
              line(
                format.myanmar(complete.myanmar, '&P &f'),
                color: accent,
                size: story ? 34 : 26,
                w: FontWeight.w800,
              ),
              SizedBox(height: story ? 24 : 8),
              if (holidays.isNotEmpty)
                line(
                  holidays.join(' · '),
                  color: t.holiday,
                  size: story ? 17 : 14,
                  w: FontWeight.w700,
                ),
              if (complete.isSabbath)
                line(
                  l10n?.sabbathReminderName ?? 'Sabbath day',
                  // The calendar's Sabbath colour reads on the light card;
                  // the moon's yellow didn't.
                  color: CalendarColors.of(context).sabbath,
                  size: story ? 16 : 13,
                  w: FontWeight.w600,
                ),
              if (good.isNotEmpty)
                line(
                  l10n?.dailySummaryGood(good) ?? 'Good: $good',
                  color: good0,
                  size: story ? 15 : 12,
                ),
              if (caution.isNotEmpty)
                line(
                  l10n?.dailySummaryCaution(caution) ?? 'Take care: $caution',
                  color: t.holiday,
                  size: story ? 15 : 12,
                ),
              const Spacer(),
              line(
                l10n?.shareCardFooter ?? 'Myanmar Calendar',
                size: story ? 14 : 11,
                w: FontWeight.w600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shares [date] as an image: a preview with Square and Story shapes, then
/// Share image; [shareText] keeps the text share one tap away.
///
/// [shareFiles] replaces the share sheet (tests).
Future<void> showDayShareSheet(
  BuildContext context, {
  required DateTime date,
  required VoidCallback shareText,
  Future<void> Function(List<XFile> files)? shareFiles,
}) {
  final l10n = AppLocalizations.of(context);
  return showAppSheet<void>(
    context: context,
    title: l10n?.shareDayTitle ?? 'Share this day',
    cancelLabel: MaterialLocalizations.of(context).closeButtonLabel,
    useRootNavigator: true,
    builder: (_) => _DayShareSheet(
      date: date,
      shareText: shareText,
      shareFiles: shareFiles,
    ),
  );
}

class _DayShareSheet extends StatefulWidget {
  const _DayShareSheet({
    required this.date,
    required this.shareText,
    this.shareFiles,
  });

  final DateTime date;
  final VoidCallback shareText;
  final Future<void> Function(List<XFile> files)? shareFiles;

  @override
  State<_DayShareSheet> createState() => _DayShareSheetState();
}

class _DayShareSheetState extends State<_DayShareSheet> {
  final _boundary = GlobalKey();
  var _shape = DayShareShape.square;
  var _busy = false;

  /// The card at 3×: 1080 px wide.
  Future<void> _shareImage() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final boundary =
          _boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) return;
      final d = widget.date;
      String two(int n) => n.toString().padLeft(2, '0');
      final name =
          'myanmar-calendar-${d.year}-${two(d.month)}-${two(d.day)}.png';
      final files = [
        XFile.fromData(
          data.buffer.asUint8List(),
          mimeType: 'image/png',
          name: name,
        ),
      ];
      final shareFiles = widget.shareFiles;
      if (shareFiles != null) {
        await shareFiles(files);
      } else {
        await share(files: files, fileNameOverrides: [name], subject: name);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = _shape.size;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSegmented<DayShareShape>(
            key: const ValueKey('share-shape'),
            segments: {
              DayShareShape.square: l10n?.shareDaySquare ?? 'Square',
              DayShareShape.story: l10n?.shareDayStory ?? 'Story',
            },
            value: _shape,
            onChanged: (s) => setState(() => _shape = s),
          ),
          const SizedBox(height: 14),
          // The preview fits the sheet; the image is the card's own size.
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .5,
              ),
              child: AspectRatio(
                aspectRatio: size.aspectRatio,
                child: FittedBox(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: RepaintBoundary(
                      key: _boundary,
                      child: DayShareCard(date: widget.date, shape: _shape),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            key: const ValueKey('share-image'),
            label: l10n?.shareDayImage ?? 'Share image',
            icon: Icons.image_outlined,
            onPressed: _busy ? null : _shareImage,
          ),
          const SizedBox(height: 8),
          AppButton(
            key: const ValueKey('share-text'),
            label: l10n?.shareDayText ?? 'Share as text',
            kind: AppButtonKind.plain,
            onPressed: () {
              Navigator.of(context).pop();
              widget.shareText();
            },
          ),
        ],
      ),
    );
  }
}
