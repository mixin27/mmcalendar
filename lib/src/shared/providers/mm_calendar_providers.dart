import 'package:ads_manager/ads_manager.dart';
import 'package:flutter_mmcalendar/flutter_mmcalendar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mmcalendar/src/utils/ads/app_ads.dart';
import 'package:mmcalendar/src/utils/shared_prefs/preference_manager.dart';
import 'package:mmcalendar/src/widgets/settings/calendar_language_list_tile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mm_calendar_providers.g.dart';

@Riverpod(keepAlive: true)
MmCalendar mmCalendar(Ref ref) {
  final config = ref.watch(mmCalendarConfigControllerProvider);
  return MmCalendar(config: config);
}

@Riverpod(keepAlive: true)
class MmCalendarConfigController extends _$MmCalendarConfigController {
  Language _fetchLanguage() {
    final prefs = ref.read(preferenceManagerProvider);

    final language = prefs.getData<String>(keyCalendarLang);

    return switch (language) {
      'Language.english' => Language.english,
      'Language.karen' => Language.karen,
      'Language.mon' => Language.mon,
      'Language.tai' => Language.tai,
      'Language.zawgyi' => Language.zawgyi,
      _ => Language.myanmar,
    };
  }

  @override
  MmCalendarConfig build() {
    final language = _fetchLanguage();
    return MmCalendarConfig(language: language);
  }

  void setLanguage(Language language) {
    final prefs = ref.read(preferenceManagerProvider);
    prefs.setData<String>(language.toString(), keyCalendarLang);
    state = MmCalendarConfig(language: language);
  }
}

@Riverpod()
AdsRepository adsRepository(Ref ref) {
  // Example config (test ids)
  // todo(me): change adUnitIds
  final config = AdsConfig(
    appId: 'ca-app-pub-7567997114394639~3076287765',
    adUnitIds: {
      'banner': AppAds.homeBannerAdUnitId, // test banner
      'interstitial': AppAds.homeInterAdUnitId, // test interstitial
      'rewarded': 'ca-app-pub-3940256099942544/5224354917', // test rewarded
      'appopen': 'ca-app-pub-3940256099942544/3419835294', // test app open
      'native': 'ca-app-pub-3940256099942544/2247696110', // test native
    },
  );
  final adapter = GoogleAdsAdapter();
  final repo = AdsRepository(adapter, config);
  return repo;
}
