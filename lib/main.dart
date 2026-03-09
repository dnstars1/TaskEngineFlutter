import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/study_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const TaskEngineApp());
}

class TaskEngineApp extends StatelessWidget {
  const TaskEngineApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF167C80);
    const accentYellow = Color(0xFFFFC107);

    return MaterialApp(
      title: 'TaskEngine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryTeal,
          primary: primaryTeal,
          secondary: accentYellow,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const LoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/calendar': (_) => const CalendarScreen(),
        '/study': (_) => const StudyScreen(),
        '/profile': (_) => const ProfileScreen(),
      },
    );
  }
}
