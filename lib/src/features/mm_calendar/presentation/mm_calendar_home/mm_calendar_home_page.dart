import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:iconly/iconly.dart';
import 'package:mmcalendar/src/l10n/l10n.dart';
import 'package:mmcalendar/src/routes/routes.dart';

import 'widgets/lanscape_calendar_view.dart';
import 'widgets/portrait_calendar_view.dart';

@RoutePage()
class MmCalendarHomePage extends StatefulHookConsumerWidget {
  const MmCalendarHomePage({super.key});

  @override
  ConsumerState<MmCalendarHomePage> createState() => _MmCalendarHomePageState();
}

class _MmCalendarHomePageState extends ConsumerState<MmCalendarHomePage> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusDay = DateTime.now();

  void _handleHeaderTap(DateTime date) async {
    final selectedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(3000),
      initialDate: date,
    );

    if (selectedDate == null) return;

    setState(() {
      _selectedDay = selectedDate;
      _focusDay = selectedDate;
    });
  }

  void _handleDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusDay = focusedDay;
    });

    context.router.push(MmCalendarDetailRoute(date: _selectedDay));
  }

  void _handlePageChanged(DateTime focusedDay) {
    setState(() {
      _focusDay = focusedDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(LocaleKeys.myanmar_calendar).tr(),
        actions: [
          IconButton(
            onPressed: () => context.router.push(const AppSettingsRoute()),
            icon: const Icon(IconlyLight.setting),
            tooltip: LocaleKeys.settings.tr(),
          ),
        ],
      ),
      body: OrientationBuilder(builder: (context, orientation) {
        if (orientation == Orientation.landscape) {
          return LanscapeCalendarView(
            selectedDay: _selectedDay,
            focusedDay: _focusDay,
            onHeaderTapped: _handleHeaderTap,
            onDaySelected: _handleDaySelected,
            onPageChanged: _handlePageChanged,
          );
        }
        return PortraitCalendarView(
          selectedDay: _selectedDay,
          focusedDay: _focusDay,
          onHeaderTapped: _handleHeaderTap,
          onDaySelected: _handleDaySelected,
          onPageChanged: _handlePageChanged,
        );
      }),
    );
  }
}
