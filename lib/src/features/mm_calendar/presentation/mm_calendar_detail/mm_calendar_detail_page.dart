import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:iconly/iconly.dart';
import 'package:mmcalendar/src/shared/shared.dart';

import 'widgets/landscape_date_detail_widget.dart';
import 'widgets/portrait_date_detail_widget.dart';

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
          return OrientationBuilder(builder: (context, orientation) {
            if (orientation == Orientation.landscape) {
              return LandscapeDateDetailWidget(
                date: _date,
                onPrevTap: _handlePreviousPage,
                onNextTap: _handleNextPage,
              );
            }

            return PortraitDateDetailWidget(
              date: _date,
              onPrevTap: _handlePreviousPage,
              onNextTap: _handleNextPage,
            );
          });
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
