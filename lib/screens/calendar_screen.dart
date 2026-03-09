import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/bottom_nav.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late int _year;
  late int _month;
  Map<String, List<Map<String, dynamic>>> _calendarData = {};
  String? _selectedDate;
  bool _loading = true;

  static const _monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _selectedDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _fetchMonth();
  }

  Future<void> _fetchMonth() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getCalendarMonth(_year, _month);
      if (!mounted) return;
      setState(() {
        _calendarData = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _prevMonth() {
    setState(() {
      _month -= 1;
      if (_month < 1) {
        _month = 12;
        _year -= 1;
      }
    });
    _fetchMonth();
  }

  void _nextMonth() {
    setState(() {
      _month += 1;
      if (_month > 12) {
        _month = 1;
        _year += 1;
      }
    });
    _fetchMonth();
  }

  List<_CalendarDay?> _generateCalendarDays() {
    final daysInMonth = DateTime(_year, _month + 1, 0).day;
    final startWeekday = DateTime(_year, _month, 1).weekday % 7; // 0=Sun
    final days = <_CalendarDay?>[];

    for (var i = 0; i < startWeekday; i++) {
      days.add(null);
    }

    for (var day = 1; day <= daysInMonth; day++) {
      final dateStr =
          '$_year-${_month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final hasDeadline = _calendarData[dateStr] != null;
      days.add(_CalendarDay(day: day, dateStr: dateStr, hasDeadline: hasDeadline));
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF167C80);
    const accentYellow = Color(0xFFFFC107);

    final calendarDays = _generateCalendarDays();
    final selectedAssignments =
        _selectedDate != null ? (_calendarData[_selectedDate] ?? []) : <Map<String, dynamic>>[];

    final todayStr =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          color: primaryTeal,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          alignment: Alignment.bottomLeft,
          child: const Text(
            'Your Semester',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: ListView(
          children: [
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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _prevMonth,
                        icon: const Icon(
                          Icons.chevron_left,
                          color: primaryTeal,
                        ),
                      ),
                      Text(
                        '${_monthNames[_month]} $_year',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      IconButton(
                        onPressed: _nextMonth,
                        icon: const Icon(
                          Icons.chevron_right,
                          color: primaryTeal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    )
                  else
                    GridView.count(
                      crossAxisCount: 7,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                      children: [
                        ...['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                            .map(
                          (d) => Center(
                            child: Text(
                              d,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF555555),
                              ),
                            ),
                          ),
                        ),
                        ...calendarDays.map((dayData) {
                          if (dayData == null) {
                            return const SizedBox.shrink();
                          }
                          final isSelected = dayData.dateStr == _selectedDate;
                          final isToday = dayData.dateStr == todayStr;

                          Color bgColor;
                          Color textColor;

                          if (isSelected) {
                            bgColor = primaryTeal;
                            textColor = Colors.white;
                          } else if (isToday) {
                            bgColor = Colors.grey.shade200;
                            textColor = const Color(0xFF333333);
                          } else {
                            bgColor = Colors.transparent;
                            textColor = const Color(0xFF333333);
                          }

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDate = dayData.dateStr;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${dayData.day}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  if (dayData.hasDeadline)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.white
                                              : accentYellow,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (selectedAssignments.isNotEmpty)
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assignments Due',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...selectedAssignments.map((assignment) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding:
                            const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: primaryTeal,
                              width: 4,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              assignment['courseName'] as String? ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF555555),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              assignment['title'] as String? ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Weight: ${assignment['weight']}%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: accentYellow,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              )
            else
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
                    'No assignments due on this day',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF555555),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 1),
    );
  }
}

class _CalendarDay {
  final int day;
  final String dateStr;
  final bool hasDeadline;

  _CalendarDay({
    required this.day,
    required this.dateStr,
    required this.hasDeadline,
  });
}
