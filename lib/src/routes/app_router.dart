import 'package:auto_route/auto_route.dart';
import 'package:mmcalendar/src/routes/routes.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          page: MmCalendarHomeRoute.page,
          path: '/',
        ),
        AutoRoute(page: MmCalendarDetailRoute.page, path: '/calendar/:date'),

        // settings
        AutoRoute(page: AppSettingsRoute.page, path: '/settings'),
        AutoRoute(page: AboutRoute.page, path: '/settings/about'),
        AutoRoute(
          page: PrivacyPolicyRoute.page,
          path: '/settings/privacy-policy',
        ),
      ];
}
