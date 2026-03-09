class DashboardSummary {
  final String workloadStatus;
  final int totalAssignments;
  final int dueThisWeek;
  final int urgentCount;
  final int totalStudyMinutes;

  DashboardSummary({
    required this.workloadStatus,
    required this.totalAssignments,
    required this.dueThisWeek,
    required this.urgentCount,
    required this.totalStudyMinutes,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      workloadStatus: json['workloadStatus'] as String? ?? 'light',
      totalAssignments: json['totalAssignments'] as int? ?? 0,
      dueThisWeek: json['dueThisWeek'] as int? ?? 0,
      urgentCount: json['urgentCount'] as int? ?? 0,
      totalStudyMinutes: json['totalStudyMinutes'] as int? ?? 0,
    );
  }
}
