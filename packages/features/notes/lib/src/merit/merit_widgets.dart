import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import 'merit_repository.dart';

/// The merit diary's colour.
const meritColor = Color(0xFFD4881C);

extension MeritKindText on MeritKind {
  String label(AppLocalizations l10n) => switch (this) {
    MeritKind.donation => l10n.meritKindDonation,
    MeritKind.precepts => l10n.meritKindPrecepts,
    MeritKind.meditation => l10n.meritKindMeditation,
    MeritKind.other => l10n.meritKindOther,
  };

  IconData get icon => switch (this) {
    MeritKind.donation => Icons.volunteer_activism_outlined,
    MeritKind.precepts => Icons.spa_outlined,
    MeritKind.meditation => Icons.self_improvement_rounded,
    MeritKind.other => Icons.favorite_border_rounded,
  };
}

/// "2,000 Ks", "30 min", or nothing.
String? meritAmount(MeritEntry e, AppLocalizations l10n) {
  final amount = e.amount;
  if (amount == null) return null;
  return switch (e.kind) {
    MeritKind.donation => l10n.meritKyats(amount),
    MeritKind.meditation => l10n.meritMinutes(amount),
    _ => null,
  };
}

/// [date]'s merit entries, each removable, and "Add merit". Nothing when
/// the diary isn't set up.
class MeritGroup extends StatelessWidget {
  const MeritGroup({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final repo = meritRepository;
    if (repo == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<MeritEntry>>(
      stream: repo.watchDay(date),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? const <MeritEntry>[];
        return AppGroup(
          label: entries.isEmpty ? null : l10n.meritTitle,
          children: [
            for (final e in entries)
              AppRow(
                key: ValueKey('merit-entry-${e.id}'),
                icon: e.kind.icon,
                iconColor: meritColor,
                title: e.kind.label(l10n),
                subtitle: [?meritAmount(e, l10n), ?e.note].join(' · ').ifEmpty,
                trailing: IconButton(
                  tooltip: l10n.delete,
                  icon: Icon(
                    Icons.close_rounded,
                    color: context.tokens.tertiaryLabel,
                    size: 20,
                  ),
                  onPressed: () => repo.remove(e.id),
                ),
              ),
            AppRow(
              key: const ValueKey('merit-add'),
              icon: entries.isEmpty ? Icons.spa_outlined : null,
              iconColor: meritColor,
              title: l10n.meritAdd,
              tone: AppRowTone.accent,
              onTap: () => showMeritSheet(context, date),
            ),
          ],
        );
      },
    );
  }
}

extension on String {
  String? get ifEmpty => isEmpty ? null : this;
}

/// Adds a merit entry on [date]: a kind, and optionally a note and kyats or
/// minutes.
Future<void> showMeritSheet(BuildContext context, DateTime date) {
  final l10n = AppLocalizations.of(context)!;
  final format = context.calendarFormat;
  return showAppSheet<void>(
    context: context,
    title:
        '${l10n.meritAdd} · ${format.weekday(date, short: true)} '
        '${format.dayMonth(date)}',
    cancelLabel: l10n.cancel,
    useRootNavigator: true,
    builder: (_) => _MeritEditor(date: date),
  );
}

class _MeritEditor extends StatefulWidget {
  const _MeritEditor({required this.date});

  final DateTime date;

  @override
  State<_MeritEditor> createState() => _MeritEditorState();
}

class _MeritEditorState extends State<_MeritEditor> {
  var _kind = MeritKind.donation;
  final _note = TextEditingController();
  final _amount = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await meritRepository?.add(
      widget.date,
      _kind,
      note: _note.text,
      amount: int.tryParse(_amount.text),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.tokens;
    InputDecoration field(String hint) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: t.fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        4,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final kind in MeritKind.values)
                AppChip(
                  key: ValueKey('merit-kind-${kind.name}'),
                  label: kind.label(l10n),
                  icon: kind.icon,
                  selected: _kind == kind,
                  onSelected: (_) => setState(() => _kind = kind),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('merit-note'),
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(color: t.label),
            decoration: field(l10n.meritNoteHint),
          ),
          if (_kind.hasAmount) ...[
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('merit-amount'),
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(color: t.label),
              decoration: field(
                _kind == MeritKind.donation
                    ? l10n.meritAmountKyats
                    : l10n.meritAmountMinutes,
              ),
            ),
          ],
          const SizedBox(height: 16),
          AppButton(
            key: const ValueKey('merit-save'),
            label: l10n.save,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

/// Views › Merit diary: the Sabbath streak, this year by kind, and every
/// entry by month; an entry opens its day.
class MeritDiaryPage extends StatelessWidget {
  const MeritDiaryPage({super.key, this.today});

  /// Today; now when null.
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final format = context.calendarFormat;
    final t = context.tokens;
    final now = DateUtils.dateOnly(today ?? DateTime.now());
    return StreamBuilder<List<MeritEntry>>(
      stream: meritRepository?.watchAll(),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? const <MeritEntry>[];
        final streak = MeritStats.sabbathStreak(entries, now);
        final year = MeritStats.year(entries, now.year);
        final months = <DateTime, List<MeritEntry>>{};
        for (final e in entries) {
          months
              .putIfAbsent(DateTime(e.date.year, e.date.month), () => [])
              .add(e);
        }
        return AppPage(
          title: l10n.meritDiaryTitle,
          previousTitle: l10n.views,
          children: [
            AppGroup(
              footer: l10n.meritStreakFooter,
              children: [
                AppRow(
                  key: const ValueKey('merit-streak'),
                  icon: Icons.local_fire_department_outlined,
                  iconColor: meritColor,
                  title: l10n.meritStreak(streak),
                ),
              ],
            ),
            AppGroup(
              label:
                  '${l10n.meritThisYear} · ${format.westernNumber(now.year)}',
              children: [
                for (final kind in MeritKind.values)
                  AppRow(
                    key: ValueKey('merit-year-${kind.name}'),
                    icon: kind.icon,
                    iconColor: meritColor,
                    title: kind.label(l10n),
                    subtitle: switch (kind) {
                      MeritKind.meditation when year.meditationMinutes > 0 =>
                        l10n.meritMinutes(year.meditationMinutes),
                      MeritKind.donation when year.donated > 0 =>
                        l10n.meritKyats(year.donated),
                      _ => null,
                    },
                    value: format.number(year.counts[kind]!),
                  ),
              ],
            ),
            if (snapshot.hasData && entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.meritEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.secondaryLabel, fontSize: 15),
                ),
              ),
            for (final MapEntry(key: month, value: list) in months.entries)
              AppGroup(
                label: format.monthYear(month),
                children: [
                  for (final e in list)
                    AppRow(
                      key: ValueKey('merit-diary-${e.id}'),
                      icon: e.kind.icon,
                      iconColor: meritColor,
                      title:
                          '${format.weekday(e.date, short: true)} '
                          '${format.dayMonth(e.date)} · ${e.kind.label(l10n)}',
                      subtitle: [
                        ?meritAmount(e, l10n),
                        ?e.note,
                      ].join(' · ').ifEmpty,
                      chevron: true,
                      onTap: () => GoRouter.of(context).push(
                        '${RoutePaths.views}/${RoutePaths.dayView}',
                        extra: e.date,
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}
