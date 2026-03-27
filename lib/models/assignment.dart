class Assignment {
  final int id;
  final String title;
  final String courseName;
  final DateTime dueDate;
  final int difficulty;
  final double priority;
  final String source;

  Assignment({
    required this.id,
    required this.title,
    required this.courseName,
    required this.dueDate,
    required this.difficulty,
    required this.priority,
    required this.source,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as int,
      title: json['title'] as String,
      courseName: json['courseName'] as String? ?? '',
      dueDate: DateTime.parse(json['dueDate'] as String),
      difficulty: json['difficulty'] as int? ?? 3,
      priority: (json['priority'] as num?)?.toDouble() ?? 0,
      source: json['source'] as String? ?? 'manual',
    );
  }

  String get priorityLabel {
    if (priority >= 50) return 'high';
    if (priority >= 10) return 'medium';
    return 'low';
  }

  int get daysLeft {
    return dueDate.difference(DateTime.now()).inDays;
  }

  String get difficultyLabel {
    switch (difficulty) {
      case 1: return 'Very Easy';
      case 2: return 'Easy';
      case 3: return 'Medium';
      case 4: return 'Hard';
      case 5: return 'Very Hard';
      default: return 'Medium';
    }
  }
}
