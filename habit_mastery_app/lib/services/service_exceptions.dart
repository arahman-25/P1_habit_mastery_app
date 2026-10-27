/// Base exception class for service validation and business logic constraints.
class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);

  @override
  String toString() => message;
}

/// Thrown when attempting to record a duplicate check-in on the same date for a habit.
/// Enforces the strict same-day policy before SQLite insert.
class DuplicateCheckInException extends ValidationException {
  final int habitId;
  final String localDate;

  DuplicateCheckInException(this.habitId, this.localDate)
      : super('A check-in already exists for habit #$habitId on $localDate.');
}

/// Thrown when a habit or check-in cannot be found in SQLite.
class EntityNotFoundException extends ValidationException {
  const EntityNotFoundException(super.message);
}
