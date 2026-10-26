class CheckIn {
  final int? id;
  final int habitId;
  final String localDate;
  final String? note;

  const CheckIn({
    this.id,
    required this.habitId,
    required this.localDate,
    this.note,
  });

  CheckIn copyWith({
    int? id,
    int? habitId,
    String? localDate,
    String? note,
  }) {
    return CheckIn(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      localDate: localDate ?? this.localDate,
      note: note ?? this.note,
    );
  }

  factory CheckIn.fromMap(Map<String, dynamic> map) {
    return CheckIn(
      id: map['id'] as int?,
      habitId: map['habitId'] as int,
      localDate: map['localDate'] as String,
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'habitId': habitId,
      'localDate': localDate,
      'note': note,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckIn &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          habitId == other.habitId &&
          localDate == other.localDate &&
          note == other.note;

  @override
  int get hashCode =>
      id.hashCode ^
      habitId.hashCode ^
      localDate.hashCode ^
      note.hashCode;

  @override
  String toString() {
    return 'CheckIn(id: $id, habitId: $habitId, localDate: $localDate, note: $note)';
  }
}
