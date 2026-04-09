import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/assignment.dart';
import '../models/dashboard_summary.dart';
import '../models/user.dart';
import '../services/ad_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
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
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _fetchData();
    if (AdService.isSupported) {
      _bannerAd = AdService.createBanner()..load();
    }
  }

  Future<void> _fetchData() async {
    try {
      final results = await Future.wait([
        ApiService.getDashboardSummary(),
        ApiService.getAssignments(),
        ApiService.getProfile(),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as DashboardSummary;
        _assignments = results[1] as List<Assignment>;
        _loading = false;
      });
      final user = results[2] as User;
      if (user.notificationsEnabled) {
        NotificationService.scheduleForAssignments(
          _assignments,
          leadTimeMinutes: user.notificationLeadTime,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _showAssignmentSheet(Assignment assignment) {
    var selectedDifficulty = assignment.difficulty;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            const labels = ['', 'Very Easy', 'Easy', 'Medium', 'Hard', 'Very Hard'];
            final days = assignment.daysLeft;

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    assignment.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    assignment.courseName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    days < 0
                        ? 'Overdue'
                        : 'Due in $days ${days == 1 ? 'day' : 'days'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: days <= 3 ? const Color(0xFFE53935) : const Color(0xFF167C80),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'How difficult is this?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (i) {
                      final level = i + 1;
                      final isSelected = level == selectedDifficulty;
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() => selectedDifficulty = level);
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? _difficultyColor(level)
                                    : Colors.grey.shade200,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$level',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              labels[level],
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected
                                    ? _difficultyColor(level)
                                    : Colors.grey.shade500,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF167C80),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: selectedDifficulty == assignment.difficulty
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              try {
                                await ApiService.updateAssignment(
                                  assignment.id,
                                  difficulty: selectedDifficulty,
                                );
                                _fetchData();
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to update: $e')),
                                );
                              }
                            },
                      child: const Text(
                        'Save',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _difficultyColor(int difficulty) {
    switch (difficulty) {
      case 1: return const Color(0xFF4CAF50);
      case 2: return const Color(0xFF8BC34A);
      case 3: return const Color(0xFFFFC107);
      case 4: return const Color(0xFFFF9800);
      case 5: return const Color(0xFFE53935);
      default: return const Color(0xFFFFC107);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF167C80);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final cardColor = Theme.of(context).cardTheme.color;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: const BottomNav(currentIndex: 0),
      );
    }

    final workloadStatus = _summary?.workloadStatus ?? 'light';
    final workloadScore = _summary?.workloadScore ?? 0;

    Color statusColor() {
      switch (workloadStatus) {
        case 'light':
          return primaryTeal;
        case 'moderate':
          return const Color(0xFFFFC107);
        case 'heavy':
          return const Color(0xFFE53935);
        default:
          return primaryTeal;
      }
    }

    String statusMessage() {
      final urgent = _summary?.urgentCount ?? 0;
      switch (workloadStatus) {
        case 'light':
          return "You're on track";
        case 'moderate':
          return '$urgent urgent ${urgent == 1 ? 'deadline' : 'deadlines'} — plan your time';
        case 'heavy':
          return '$urgent urgent deadlines — prioritize now';
        default:
          return "You're on track";
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
          return const Color(0xFFFFC107);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
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
                color: cardColor,
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'This Week',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Circular gauge + breakdown side by side
                  Row(
                    children: [
                      // Circular progress gauge
                      SizedBox(
                        width: 110,
                        height: 110,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 110,
                              height: 110,
                              child: CircularProgressIndicator(
                                value: workloadScore / 100,
                                strokeWidth: 10,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(statusColor()),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$workloadScore',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor(),
                                  ),
                                ),
                                Text(
                                  workloadStatus[0].toUpperCase() +
                                      workloadStatus.substring(1),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Breakdown details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status message
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  workloadStatus == 'heavy'
                                      ? Icons.warning_rounded
                                      : workloadStatus == 'moderate'
                                          ? Icons.schedule
                                          : Icons.check_circle_outline,
                                  color: statusColor(),
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    statusMessage(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _breakdownRow(
                              Icons.assignment_outlined,
                              '${_summary?.dueThisWeek ?? 0} due this week',
                              onSurfaceVariant,
                            ),
                            const SizedBox(height: 6),
                            _breakdownRow(
                              Icons.timer_outlined,
                              '${_summary?.urgentCount ?? 0} due in 3 days',
                              _summary != null && _summary!.urgentCount > 0
                                  ? const Color(0xFFE53935)
                                  : onSurfaceVariant,
                            ),
                            const SizedBox(height: 6),
                            _breakdownRow(
                              Icons.menu_book_outlined,
                              '${_summary?.totalStudyMinutes ?? 0} min studied',
                              onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_bannerAd != null)
              Container(
                alignment: Alignment.center,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                margin: const EdgeInsets.symmetric(vertical: 16),
                child: AdWidget(ad: _bannerAd!),
              )
            else
              const SizedBox(height: 24),
            Text(
              'Upcoming Assignments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to set difficulty',
              style: TextStyle(
                fontSize: 12,
                color: onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (_assignments.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'No upcoming assignments',
                    style: TextStyle(fontSize: 13, color: onSurfaceVariant),
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

              return GestureDetector(
                onTap: () => _showAssignmentSheet(assignment),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
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
                              style: TextStyle(
                                fontSize: 12,
                                color: onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              assignment.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  dueDateStr,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Difficulty dots
                                Row(
                                  children: List.generate(5, (i) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 3),
                                      child: Icon(
                                        Icons.circle,
                                        size: 8,
                                        color: i < assignment.difficulty
                                            ? _difficultyColor(assignment.difficulty)
                                            : Colors.grey.shade300,
                                      ),
                                    );
                                  }),
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
                ),
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }

  Widget _breakdownRow(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: color),
        ),
      ],
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
