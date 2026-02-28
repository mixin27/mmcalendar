# Events System (Production Rebuild)

This feature is being migrated to a production-grade event architecture with:

1. Domain-first validation and sanitization.
2. Orchestrated event flow (persist + reminders) instead of UI-driven side effects.
3. Predictable recurrence expansion for date-range queries.
4. UI flow state for quick filters and refresh consistency.

## Current Migration (Implemented)

- `EventValidationService` is now the single source of truth for event validation rules.
- `CreateUserEvent` and `UpdateUserEvent` now both use:
  - centralized validation
  - normalized persistence payloads
- `EventFlowService` orchestrates:
  - create/update
  - notification cancel/reschedule
- `EventFormBloc` now:
  - keeps immutable `createdAt` for edits
  - re-validates after each field change
  - deduplicates reminders
  - normalizes tags
  - delegates save flow to `EventFlowService`
- `RecurrenceRule.generateOccurrences` has been hardened for:
  - correct occurrence counting from series start
  - weekly interval + weekdays behavior
  - safer loop termination guards

## Next Steps

1. Split persistence model into normalized tables:
   - `events`
   - `event_reminders`
   - `event_recurrence_rules`
   - `event_recurrence_exceptions`
2. Add timezone-aware scheduling fields:
   - `timezone_id`
   - `start_at_utc`
   - `end_at_utc`
3. Introduce event command handlers (application layer):
   - `CreateEventCommand`
   - `UpdateEventCommand`
   - `CompleteOccurrenceCommand`
   - `DeleteOccurrenceCommand`
4. Add automated test suites:
   - recurrence engine edge cases
   - notification scheduling contracts
   - repository consistency tests
