import 'package:flutter/material.dart';

import '../models/assignment.dart';
import '../models/dashboard_summary.dart';
import '../services/api_service.dart';
import '../widgets/bottom_nav.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  DashboardSummary? _summary;
  List<Assignment> _assignments = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final results = await Future.wait([
        ApiService.getDashboardSummary(),
        ApiService.getAssignments(),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as DashboardSummary;
        _assignments = results[1] as List<Assignment>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF167C80);
    const accentYellow = Color(0xFFFFC107);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: const Text(
            'Dashboard',
            style: TextStyle(
              color: Color(0xFF333333),
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: const BottomNav(currentIndex: 0),
      );
    }

    final workloadStatus = _summary?.workloadStatus ?? 'light';

    Color statusColor() {
      switch (workloadStatus) {
        case 'light':
          return primaryTeal;
        case 'moderate':
          return accentYellow;
        case 'heavy':
          return const Color(0xFFE53935);
        default:
          return primaryTeal;
      }
    }

    IconData priorityIcon(String priority) {
      switch (priority) {
        case 'high':
          return Icons.local_fire_department;
        case 'medium':
          return Icons.warning_amber_rounded;
        case 'low':
        default:
          return Icons.nightlight_round;
      }
    }

    Color priorityColor(String priority) {
      switch (priority) {
        case 'high':
          return const Color(0xFFE53935);
        case 'medium':
          return accentYellow;
        case 'low':
        default:
          return Colors.grey.shade300;
      }
    }

    Color priorityTextColor(String priority) {
      switch (priority) {
        case 'high':
          return Colors.white;
        case 'medium':
          return const Color(0xFF333333);
        case 'low':
        default:
          return Colors.grey.shade700;
      }
    }

    String statusEmoji() {
      switch (workloadStatus) {
        case 'light':
          return '\u{1F7E2}';
        case 'moderate':
          return '\u{1F7E1}';
        case 'heavy':
          return '\u{1F534}';
        default:
          return '\u{1F7E2}';
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: ListView(
          children: [
            // Weekly workload card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'This Week',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: statusColor(),
                            width: 8,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              statusEmoji(),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: statusColor(),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              workloadStatus,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: statusColor(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          Text(
                            '${_summary?.dueThisWeek ?? 0} Deadlines',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF555555),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_summary?.totalStudyMinutes ?? 0} min studied',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: accentYellow,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Upcoming Assignments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            if (_assignments.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'No upcoming assignments',
                    style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
                  ),
                ),
              ),
            ..._assignments.map((assignment) {
              final priority = assignment.priorityLabel;
              final badgeBg = priorityColor(priority);
              final badgeText = priorityTextColor(priority);
              final days = assignment.daysLeft;

              final dueDateStr =
                  '${_monthName(assignment.dueDate.month)} ${assignment.dueDate.day}, ${assignment.dueDate.year}';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            assignment.courseName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF555555),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            assignment.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dueDateStr,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF555555),
                                ),
                              ),
                              Text(
                                '${assignment.weight}%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: accentYellow,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            days < 0
                                ? 'Overdue'
                                : '$days ${days == 1 ? 'day' : 'days'} left',
                            style: const TextStyle(
                              fontSize: 12,
                              color: primaryTeal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            priorityIcon(priority),
                            size: 16,
                            color: badgeText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            priority[0].toUpperCase() +
                                priority.substring(1).toLowerCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: badgeText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month];
  }
}
