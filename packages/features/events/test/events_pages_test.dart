import 'package:dartz/dartz.dart';
import 'package:events/events.dart';
import 'package:events/src/presentation/bloc/event_categories_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

final _family = EventCategory(
  id: 4,
  name: 'Family',
  iconName: 'family_restroom',
  colorCode: 0xFFE0457B,
  isDefault: true,
  createdAt: DateTime(2026),
);
final _club = EventCategory(
  id: 9,
  name: 'Photo club',
  iconName: 'favorite',
  colorCode: 0xFF16A3B0,
  createdAt: DateTime(2026),
);

/// In-memory repository with one event a day ago, today and tomorrow.
class _Repository implements EventsRepository {
  final categories = [_family, _club];
  final deleted = <int>[];
  EventCategory? updated;

  List<Event> _eventsOn(DateTime date) => [
    if (DateUtils.isSameDay(date, DateTime.now()))
      Event(
        id: 1,
        title: 'Team call',
        eventDate: DateUtils.dateOnly(date),
        category: _family,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
  ];

  @override
  Future<Either<Failure, List<Event>>> getEventsByDate(DateTime date) async =>
      Right(_eventsOn(date));

  @override
  Future<Either<Failure, List<Event>>> getEventsByDateRange(
    DateTime start,
    DateTime end, {
    bool expandRecurring = true,
  }) async => Right(_eventsOn(DateTime.now()));

  @override
  Future<Either<Failure, List<EventCategory>>> getAllCategories() async =>
      Right(categories);

  @override
  Future<Either<Failure, EventCategory>> updateCategory(
    EventCategory category,
  ) async {
    updated = category;
    return Right(category);
  }

  @override
  Future<Either<Failure, void>> deleteCategory(int categoryId) async {
    deleted.add(categoryId);
    return const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Scheduler implements SmartNotificationScheduler {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

Widget _app(AppStyle style, Widget home) => MaterialApp(
  theme: AppTheme.build(style: style, colorScheme: AppColorSchemes.modernLight),
  home: home,
);

void main() {
  late _Repository repository;

  setUp(() async {
    await GetIt.instance.reset();
    repository = _Repository();
    GetIt.instance.registerSingleton<EventsRepository>(repository);
  });
  tearDown(() => GetIt.instance.reset());

  void size(WidgetTester tester) {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 1400);
    addTearDown(tester.view.reset);
  }

  for (final style in [AppStyle.clear, AppStyle.material]) {
    group('${style.name} style', () {
      testWidgets('Events lists the day with a Categories entry point', (
        tester,
      ) async {
        size(tester);
        final bloc = UserEventsBloc(
          getEventsByDate: GetEventsByDate(repository),
          getEventsByDateRange: GetEventsByDateRange(repository),
          getUpcomingEvents: GetUpcomingEvents(repository),
          searchEvents: SearchUserEvents(repository),
          toggleEventCompletion: ToggleEventCompletion(repository),
          deleteEvent: DeleteUserEvent(repository),
          watchEvents: WatchUserEvents(repository),
          watchEventsByDateRange: WatchEventsByDateRange(repository),
          eventsRepository: repository,
          smartScheduler: _Scheduler(),
        );
        addTearDown(bloc.close);
        await tester.pumpWidget(
          _app(
            style,
            BlocProvider.value(value: bloc, child: const EventsListPage()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Team call'), findsOneWidget);
        expect(find.byType(EventRow), findsOneWidget);
        if (style == AppStyle.material) {
          expect(find.byType(FloatingActionButton), findsOneWidget);
        } else {
          expect(find.byTooltip('New Event'), findsOneWidget);
        }

        await tester.tap(find.byTooltip('More'));
        await tester.pumpAndSettle();
        expect(find.text('Categories'), findsOneWidget);
        expect(find.text('Pick a date'), findsOneWidget);
      });

      testWidgets('Categories edits and deletes custom ones only', (
        tester,
      ) async {
        size(tester);
        final bloc = EventCategoriesBloc(
          getEventCategories: GetEventCategories(repository),
          createEventCategory: CreateEventCategory(repository),
          repository: repository,
        )..add(const LoadEventCategories());
        addTearDown(bloc.close);
        await tester.pumpWidget(
          _app(
            style,
            BlocProvider.value(value: bloc, child: const CategoriesPage()),
          ),
        );
        await tester.pumpAndSettle();
        expect(bloc.state, isA<EventCategoriesLoaded>());

        // Default categories are locked.
        await tester.tap(find.text('Family'));
        await tester.pumpAndSettle();
        expect(find.text('Edit Category'), findsNothing);

        await tester.tap(find.text('Photo club'));
        await tester.pumpAndSettle();
        expect(find.text('Edit Category'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'Photo walks');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(repository.updated?.name, 'Photo walks');
        expect(find.text('Photo walks'), findsOneWidget);

        await tester.tap(find.text('Photo walks'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete Category'));
        await tester.pumpAndSettle();
        expect(
          style == AppStyle.clear
              ? find.byType(CupertinoAlertDialog)
              : find.byType(AlertDialog),
          findsOneWidget,
        );
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        expect(repository.deleted, [9]);
        expect(find.text('Photo walks'), findsNothing);
      });
    });
  }
}
