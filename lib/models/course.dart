class Course {
  final int id;
  final String name;
  final int assignmentCount;
  final int sessionCount;

  Course({
    required this.id,
    required this.name,
    required this.assignmentCount,
    required this.sessionCount,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as int,
      name: json['name'] as String,
      assignmentCount: json['assignmentCount'] as int? ?? 0,
      sessionCount: json['sessionCount'] as int? ?? 0,
    );
  }
}
