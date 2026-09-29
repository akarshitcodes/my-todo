enum TaskPriority {
  low,
  medium,
  high,
}

class Task {
  final String id;
  String title;
  bool isCompleted;
  TaskPriority priority;
  DateTime? dueDate;
  DateTime? reminderAt;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.reminderAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'is_completed': isCompleted ? 1 : 0,
      'priority': priority.index,
      'due_date': dueDate?.millisecondsSinceEpoch,
      'reminder_at': reminderAt?.millisecondsSinceEpoch,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    final priorityValue =
        map['priority'] as int? ?? TaskPriority.medium.index;

    final safePriority =
        priorityValue >= 0 &&
                priorityValue < TaskPriority.values.length
            ? priorityValue
            : TaskPriority.medium.index;

    final dueDateValue = map['due_date'] as int?;
    final reminderValue = map['reminder_at'] as int?;

    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      isCompleted: (map['is_completed'] as int) == 1,
      priority: TaskPriority.values[safePriority],
      dueDate: dueDateValue == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              dueDateValue,
            ),
      reminderAt: reminderValue == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              reminderValue,
            ),
    );
  }
}