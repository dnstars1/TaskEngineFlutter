class StudyStats {
  final int totalMinutes;
  final List<ModuleStats> modules;

  StudyStats({
    required this.totalMinutes,
    required this.modules,
  });

  factory StudyStats.fromJson(Map<String, dynamic> json) {
    return StudyStats(
      totalMinutes: json['totalMinutes'] as int? ?? 0,
      modules: (json['modules'] as List<dynamic>?)
              ?.map((m) => ModuleStats.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ModuleStats {
  final String courseName;
  final int courseId;
  final int totalMinutes;
  final int sessionCount;

  ModuleStats({
    required this.courseName,
    required this.courseId,
    required this.totalMinutes,
    required this.sessionCount,
  });

  factory ModuleStats.fromJson(Map<String, dynamic> json) {
    return ModuleStats(
      courseName: json['courseName'] as String,
      courseId: json['courseId'] as int,
      totalMinutes: json['totalMinutes'] as int? ?? 0,
      sessionCount: json['sessionCount'] as int? ?? 0,
    );
  }
}
