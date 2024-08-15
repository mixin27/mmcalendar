import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:iconly/iconly.dart';
import 'package:mmcalendar/src/shared/shared.dart';
import 'package:mmcalendar/src/utils/dates.dart';

@RoutePage()
class MmCalendarDetailPage extends StatefulHookConsumerWidget {
  const MmCalendarDetailPage({super.key, required this.date});

  @PathParam('date')
  final DateTime date;

  @override
  ConsumerState<MmCalendarDetailPage> createState() =>
      _MmCalendarDetailPageState();
}

class _MmCalendarDetailPageState extends ConsumerState<MmCalendarDetailPage> {
  // ignore: prefer_final_fields
  int _currentPageIndex = 600;
  PageController? _pageController;

  DateTime _date = DateTime.now();

  @override
  void initState() {
    _date = widget.date;
    _pageController = PageController(initialPage: _currentPageIndex);
    super.initState();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _handlePageChange(int position) {
    if (_currentPageIndex > position) {
      // substract
      setState(() {
        _date = _date.subtract(const Duration(days: 1));
        _currentPageIndex -= 1;
      });
    } else {
      // add
      setState(() {
        _date = _date.add(const Duration(days: 1));
        _currentPageIndex += 1;
      });
    }
  }

  void _handlePreviousPage() {
    _pageController?.animateToPage(
      _currentPageIndex - 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  void _handleNextPage() {
    _pageController?.animateToPage(
      _currentPageIndex + 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  void _handleDatePicker() async {
    final selectedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(3000),
      initialDate: _date,
    );

    if (selectedDate == null) return;

    setState(() {
      _date = selectedDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mmCalendar = ref.watch(mmCalendarProvider);

    // final calLanguage = ref.watch(calendarLanguageControllerProvider);
    // final langCatalog = LanguageCatalog(language: calLanguage);

    final day = DateFormat().add_d().format(_date);
    final dow = DateFormat().add_EEEE().format(_date);
    final monthAndYear = DateFormat('MMMM, yyyy').format(_date);

    final mmDate = mmCalendar.fromDateTime(_date);
    final fortnightDay = mmDate.getFortnightDay();

    final mmDow = mmDate.format('En');

    final mmDay = fortnightDay.isNotEmpty
        ? mmDate.format('M p f r n')
        : mmDate.format('M p n');

    final mmDateFull = fortnightDay.isNotEmpty
        ? mmDate.format()
        : mmDate.format('S s k, B y k, M p, En');

    final languageCatalog = LanguageCatalog();
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

    List<String> holidays = mmDate.holidays;
    final holidayColor = Theme.of(context).colorScheme.error;
    final isPublicHoliday = isHoliday(_date, mmDate);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: _handleDatePicker,
            icon: const Icon(IconlyLight.calendar),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: _handlePageChange,
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
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
                        nagahle.isEmpty
                            ? ''
                            : '$nagaMM$headMM $nagahle $facingMM',
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
              Expanded(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _handlePreviousPage,
                      iconSize: 35,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$mmDow ($dow)',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (isPublicHoliday) ...[
                            const SizedBox(height: 10),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
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
                                  fontSize:
                                      MediaQuery.sizeOf(context).width / 2,
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
                            date: _date,
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
                    IconButton(
                      onPressed: _handleNextPage,
                      iconSize: 35,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

class MmDate extends HookConsumerWidget {
  const MmDate({
    super.key,
    required this.date,
  });

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mmCalendar = ref.watch(mmCalendarProvider);
    final mmDate = mmCalendar.fromDateTime(date);

    final fortnightDay = mmDate.getFortnightDay();

    final pattern = fortnightDay.isNotEmpty
        ? 'S s k, B y k, M p f r, En'
        : 'S s k, B y k, M p f, En';

    final text = mmDate.format(pattern);

    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}

class DayOfWeek extends HookConsumerWidget {
  const DayOfWeek({
    super.key,
    required this.date,
  });

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mmCalendar = ref.watch(mmCalendarProvider);
    final mmDate = mmCalendar.fromDateTime(date);

    final day = DateFormat('MMMM, yyyy').format(date);
    final dow = DateFormat().add_EEEE().format(date);
    final mmDow = mmDate.format('E n');

    final astrologicalDay = mmDate.astro.getAstrologicalDay();
    final sabbath = mmDate.astro.getSabbath();

    final nagahle = mmDate.astro.getNagahle();
    final nagahleText = 'နဂါးခေါင်း $nagahle မြောက်သို့';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          day,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                // color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
        const SizedBox(height: 10),
        Text(
          dow,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                // color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
        const SizedBox(height: 10),
        Text(
          mmDow,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w500,
              ),
        ),
        if (nagahle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            nagahleText,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
        if (astrologicalDay.isNotEmpty || sabbath.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                astrologicalDay,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              if (sabbath.isNotEmpty) ...[
                if (astrologicalDay.isNotEmpty)
                  Text(
                    ', ',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                Text(
                  sabbath,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class MmYear extends StatelessWidget {
  const MmYear({
    super.key,
    required this.mmDate,
  });

  final MyanmarDate mmDate;

  @override
  Widget build(BuildContext context) {
    final mmYearLabel = mmDate.format('B');
    final mmYear = mmDate.format('y k');
    final buddhistEraLabel = mmDate.format('S');
    final buddhistEra = mmDate.format('s k');

    return Row(
      children: [
        Expanded(
          child: ListTile(
            title: Text(
              buddhistEra,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(buddhistEraLabel),
          ),
        ),
        Expanded(
          child: ListTile(
            title: Text(
              mmYear,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(mmYearLabel),
          ),
        ),
      ],
    );
  }
}

class AstroList extends StatelessWidget {
  const AstroList({
    super.key,
    required this.astro,
  });

  final Astro astro;

  @override
  Widget build(BuildContext context) {
    final mahabote = astro.getMahabote();
    final yearName = astro.getYearName();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Astro',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        ListTile(
          title: const Text('Mahabote'),
          subtitle: Text(mahabote),
        ),
        const Divider(),
        ListTile(
          title: const Text('Year name'),
          subtitle: Text(yearName),
        ),
        const Divider(),
        ListTile(
          title: const Text('Mahabote'),
          subtitle: Text(mahabote),
        ),
        const Divider(),
      ],
    );
  }
}
