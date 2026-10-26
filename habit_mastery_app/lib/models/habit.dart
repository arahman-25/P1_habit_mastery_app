class Habit {
  final int? id;
  final String title;
  final String category;
  final int weeklyTarget;
  final String startedLocalDate;
  final String? motivation;

  const Habit({
    this.id,
    required this.title,
    required this.category,
    required this.weeklyTarget,
    required this.startedLocalDate,
    this.motivation,
  });

  Habit copyWith({
    int? id,
    String? title,
    String? category,
    int? weeklyTarget,
    String? startedLocalDate,
    String? motivation,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      weeklyTarget: weeklyTarget ?? this.weeklyTarget,
      startedLocalDate: startedLocalDate ?? this.startedLocalDate,
      motivation: motivation ?? this.motivation,
    );
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as int?,
      title: map['title'] as String,
      category: map['category'] as String,
      weeklyTarget: map['weeklyTarget'] as int,
      startedLocalDate: map['startedLocalDate'] as String,
      motivation: map['motivation'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'category': category,
      'weeklyTarget': weeklyTarget,
      'startedLocalDate': startedLocalDate,
      'motivation': motivation,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Habit &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          category == other.category &&
          weeklyTarget == other.weeklyTarget &&
          startedLocalDate == other.startedLocalDate &&
          motivation == other.motivation;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      category.hashCode ^
      weeklyTarget.hashCode ^
      startedLocalDate.hashCode ^
      motivation.hashCode;

  @override
  String toString() {
    return 'Habit(id: $id, title: $title, category: $category, weeklyTarget: $weeklyTarget, startedLocalDate: $startedLocalDate, motivation: $motivation)';
  }
}
