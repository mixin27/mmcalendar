import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mmcalendar/src/shared/shared.dart';
import 'package:mmcalendar/src/utils/dates.dart';

class PortraitDateDetailWidget extends HookConsumerWidget {
  const PortraitDateDetailWidget({
    super.key,
    required this.date,
    this.onPrevTap,
    this.onNextTap,
  });

  final DateTime date;
  final VoidCallback? onPrevTap;
  final VoidCallback? onNextTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mmCalendar = ref.watch(mmCalendarProvider);
    final config = ref.watch(mmCalendarConfigControllerProvider);

    final day = DateFormat().add_d().format(date);
    final dow = DateFormat().add_EEEE().format(date);
    final monthAndYear = DateFormat('MMMM, yyyy').format(date);

    final mmDate = mmCalendar.fromDateTime(date);
    final fortnightDay = mmDate.getFortnightDay();

    final mmDow = mmDate.format('En');

    final mmDay = fortnightDay.isNotEmpty
        ? mmDate.format('M p f r n')
        : mmDate.format('M p n');

    final mmDateFull = fortnightDay.isNotEmpty
        ? mmDate.format()
        : mmDate.format('S s k, B y k, M p, En');

    final languageCatalog = LanguageCatalog(language: config.language);
    final astro = mmDate.astro;

    final sabbath = astro.getSabbath();
    final astrologicalDay = astro.getAstrologicalDay();

    final nagaMM = languageCatalog.translate('Naga');
    final headMM = languageCatalog.translate('Head');
    final facingMM = languageCatalog.translate('Facing');
    final nagahle = astro.getNagahle();

    final bornMM = languageCatalog.translate('Born');
    final mahabote = astro.getMahabote();

    final yearMM = languageCatalog.translate('Year');
    final yearname = astro.getYearName();

    final nakhatMM = languageCatalog.translate('Nakhat');
    final nakhat = astro.getNakhat();

    final nagapor = astro.getNagapor();

    List<String> holidays =
        mmDate.getHolidays(langCatalog: mmCalendar.languageCatalog);
    final holidayColor = Theme.of(context).colorScheme.error;
    final isPublicHoliday = isHoliday(date, mmDate);

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPublicHoliday
                  ? Theme.of(context).colorScheme.errorContainer
                  : Theme.of(context).colorScheme.primaryContainer,
              border: Border.all(
                color: isPublicHoliday
                    ? holidayColor
                    : Theme.of(context).colorScheme.primary,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: Text(
              mmDateFull,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  sabbath,
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  // tr(LocaleKeys.nagahle, args: [nagahle]),
                  nagahle.isEmpty ? '' : '$nagaMM$headMM $nagahle $facingMM',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  astrologicalDay,
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: Text(
                  mahabote.isEmpty ? '' : '$mahabote $bornMM',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  yearname.isEmpty ? '' : '$yearname $yearMM',
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: Text(
                  nakhat.isEmpty ? '' : '$nakhat $nakhatMM',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  nagapor,
                  textAlign: TextAlign.start,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: Text(
                  '',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            if (onPrevTap != null)
              IconButton(
                onPressed: onPrevTap,
                iconSize: 35,
                icon: const Icon(Icons.chevron_left),
              ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    mmCalendar.language == Language.english
                        ? dow
                        : '$mmDow ($dow)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (isPublicHoliday) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        holidays.join(', '),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: holidayColor),
                      ),
                    ),
                  ],
                  Text(
                    day,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: MediaQuery.sizeOf(context).width / 2,
                          color: isPublicHoliday
                              ? holidayColor
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  Text(
                    monthAndYear,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  MoonPhaseWidget(
                    date: date,
                    size: MediaQuery.sizeOf(context).width / 6,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    mmDay,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            if (onNextTap != null)
              IconButton(
                onPressed: onNextTap,
                iconSize: 35,
                icon: const Icon(Icons.chevron_right),
              ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
