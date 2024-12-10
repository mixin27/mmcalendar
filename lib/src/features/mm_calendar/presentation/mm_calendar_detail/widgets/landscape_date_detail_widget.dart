import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mmcalendar/src/shared/shared.dart';
import 'package:mmcalendar/src/utils/dates.dart';
import 'package:mmcalendar/src/utils/google_ads/ads_helper.dart';

class LandscapeDateDetailWidget extends ConsumerStatefulWidget {
  const LandscapeDateDetailWidget({
    super.key,
    required this.date,
    this.onPrevTap,
    this.onNextTap,
  });

  final DateTime date;
  final VoidCallback? onPrevTap;
  final VoidCallback? onNextTap;

  @override
  ConsumerState<LandscapeDateDetailWidget> createState() =>
      _LandscapeDateDetailWidgetState();
}

class _LandscapeDateDetailWidgetState
    extends ConsumerState<LandscapeDateDetailWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    loadBannerAd();
  }

  void loadBannerAd() {
    final ad = AdsHelper.loadBannerAd(
      onLoaded: () {
        setState(() {
          _isAdLoaded = true;
        });
      },
    );
    setState(() {
      _bannerAd = ad;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mmCalendar = ref.watch(mmCalendarProvider);
    final config = ref.watch(mmCalendarConfigControllerProvider);

    final day = DateFormat().add_d().format(widget.date);
    final dow = DateFormat().add_EEEE().format(widget.date);
    final monthAndYear = DateFormat('MMMM, yyyy').format(widget.date);

    final mmDate = mmCalendar.fromDateTime(widget.date);
    final fortnightDay = mmDate.getFortnightDay();

    final mmDow = mmDate.format('En');

    final mmDay = fortnightDay.isNotEmpty
        ? mmDate.format('M p f r n')
        : mmDate.format('M p n');

    final mmDateFull = fortnightDay.isNotEmpty
        ? mmDate.format()
        : mmDate.format('S s k, B y k, M p, En');

    final astro = mmDate.astro;

    final sabbath = astro.getSabbath();
    final astrologicalDay = astro.getAstrologicalDay();

    final languageCatalog = LanguageCatalog(language: config.language);
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

    List<String> holidays = mmDate.holidays;
    final holidayColor = Theme.of(context).colorScheme.error;
    final isPublicHoliday = isHoliday(widget.date, mmDate);

    return Row(
      children: [
        if (widget.onPrevTap != null)
          IconButton(
            onPressed: widget.onPrevTap,
            iconSize: 35,
            icon: const Icon(Icons.chevron_left),
          ),
        Expanded(
          child: ListView(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          mmCalendar.language == Language.english
                              ? dow
                              : '$mmDow ($dow)',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (isPublicHoliday && holidays.isNotEmpty) ...[
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
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                fontSize: MediaQuery.sizeOf(context).height / 4,
                                color: isPublicHoliday
                                    ? holidayColor
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        Text(
                          monthAndYear,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        MoonPhaseWidget(
                          date: widget.date,
                          size: 50,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          mmDay,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                width: 8,
                                color: isPublicHoliday
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            // borderRadius:
                            //     const BorderRadius.all(Radius.circular(4)),
                          ),
                          child: Text(
                            mmDateFull,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(),
                        ),
                        if (_bannerAd != null && _isAdLoaded) ...[
                          SizedBox(
                            width: double.infinity,
                            height: _bannerAd!.size.height.toDouble(),
                            child: AdWidget(ad: _bannerAd!),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (sabbath.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '\u2022 $sabbath',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                        if (nagapor.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '\u2022 $nagapor',
                            textAlign: TextAlign.start,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                        if (nagahle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '\u2022 $nagaMM$headMM $nagahle $facingMM',
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                        if (astrologicalDay.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '\u2022 $astrologicalDay',
                            textAlign: TextAlign.start,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                        if (mahabote.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '\u2022 $mahabote $bornMM',
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                        if (nakhat.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '\u2022 $nakhat $nakhatMM',
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                        if (yearname.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '\u2022 $yearname $yearMM',
                            textAlign: TextAlign.start,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (widget.onNextTap != null)
          IconButton(
            onPressed: widget.onNextTap,
            iconSize: 35,
            icon: const Icon(Icons.chevron_right),
          ),
      ],
    );
  }
}
