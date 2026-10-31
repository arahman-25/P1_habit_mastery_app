/// Base exception for service and data validation errors.
class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);

  @override
  String toString() => message;
}

/// Thrown when attempting to check in twice on the same day for a habit.
class DuplicateCheckInException extends ValidationException {
  final int habitId;
  final String localDate;

  DuplicateCheckInException(this.habitId, this.localDate)
      : super('A check-in already exists for habit #$habitId on $localDate.');
}

/// Thrown when a habit or check-in is not found.
class EntityNotFoundException extends ValidationException {
  const EntityNotFoundException(super.message);
}
