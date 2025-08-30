import 'dart:developer';

import 'package:ads_manager/ads_manager.dart';
import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:iconly/iconly.dart';
import 'package:mmcalendar/src/l10n/l10n.dart';
import 'package:mmcalendar/src/routes/routes.dart';
import 'package:mmcalendar/src/shared/shared.dart';
import 'package:mmcalendar/src/utils/ads/app_ads.dart';
import 'package:mmcalendar/src/utils/onesignal/onesignal.dart';

import 'widgets/lanscape_calendar_view.dart';
import 'widgets/portrait_calendar_view.dart';

@RoutePage()
class MmCalendarHomePage extends StatefulHookConsumerWidget {
  const MmCalendarHomePage({super.key});

  @override
  ConsumerState<MmCalendarHomePage> createState() => _MmCalendarHomePageState();
}

class _MmCalendarHomePageState extends ConsumerState<MmCalendarHomePage> {
  bool adLoaded = false;

  DateTime _selectedDay = DateTime.now();
  DateTime _focusDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    initOnesignal();
  }

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
    final adsRepo = ref.watch(adsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        // title: const Text().tr(),
        title: Text(
          LocaleKeys.myanmar_calendar,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 30,
            letterSpacing: 1.5,
            shadows: [
              BoxShadow(
                blurRadius: 10,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.4),
                offset: const Offset(2, 2),
              ),
            ],
          ),
        ).tr(),
        actions: [
          IconButton(
            onPressed: () => context.router.push(const AppSettingsRoute()),
            icon: const Icon(IconlyLight.setting),
            tooltip: LocaleKeys.settings.tr(),
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            return LanscapeCalendarView(
              selectedDay: _selectedDay,
              focusedDay: _focusDay,
              onHeaderTapped: _handleHeaderTap,
              onDaySelected: _handleDaySelected,
              onPageChanged: _handlePageChanged,
            );
          }
          return Column(
            children: [
              // Home banner ad widget
              // banner at bottom
              BannerAdView(
                bannerControllerFuture: adsRepo.loadBanner(
                  AppAds.homeBannerAdUnitId,
                  width: AdSizeConfig.banner.width,
                  height: AdSizeConfig.banner.height,
                ),
                height: AdSizeConfig.banner.height.toDouble(),
              ),
              Expanded(
                child: PortraitCalendarView(
                  selectedDay: _selectedDay,
                  focusedDay: _focusDay,
                  onHeaderTapped: _handleHeaderTap,
                  onDaySelected: _handleDaySelected,
                  onPageChanged: _handlePageChanged,
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            final inter = await adsRepo.loadInterstitial(
              AppAds.homeInterAdUnitId,
            );
            await inter.show();
          } catch (e) {
            log('Interstitial failed: $e');
          }
        },
        child: const Icon(Icons.ad_units),
      ),
    );
  }

  @override
  void dispose() {
    // banner.dispose();
    super.dispose();
  }
}
