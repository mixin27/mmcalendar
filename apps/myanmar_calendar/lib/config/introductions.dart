import 'package:promo/promo.dart';
import 'package:whats_new/whats_new.dart';

import 'di_setup.dart';

/// Debug: forget that onboarding and What's new were seen, so both show on
/// the next launch.
Future<void> resetIntroductions() async {
  await getIt<PromoRepository>().clearAllData();
  await getIt<WhatsNewStore>().reset('2.2.0');
}
