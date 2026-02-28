import 'package:shared_core/shared_core.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../entities/event.dart';
import '../repositories/events_repository.dart';

/// Use case for searching events by text query
class SearchUserEvents implements UseCase<List<Event>, SearchUserEventsParams> {
  final EventsRepository repository;

  SearchUserEvents(this.repository);

  @override
  Future<Either<Failure, List<Event>>> call(
    SearchUserEventsParams params,
  ) async {
    // Validate query
    if (params.query.trim().isEmpty) {
      return Left(ValidationFailure('Search query cannot be empty'));
    }

    return await repository.searchEvents(params.query);
  }
}

class SearchUserEventsParams extends Equatable {
  final String query;

  const SearchUserEventsParams(this.query);

  @override
  List<Object?> get props => [query];
}
