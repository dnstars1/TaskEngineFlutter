import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/study_screen.dart';
import 'screens/profile_screen.dart';
import 'services/ad_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  await AdService.init();
  runApp(const TaskEngineApp());
}

class ThemeNotifier extends ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  void setDark(bool value) {
    if (_isDark != value) {
      _isDark = value;
      notifyListeners();
    }
  }
}

final themeNotifier = ThemeNotifier();

class TaskEngineApp extends StatefulWidget {
  const TaskEngineApp({super.key});

  @override
  State<TaskEngineApp> createState() => _TaskEngineAppState();
}

class _TaskEngineAppState extends State<TaskEngineApp> {
  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF167C80);
    const accentYellow = Color(0xFFFFC107);

    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        primary: primaryTeal,
        secondary: accentYellow,
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F6F9),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF333333),
        elevation: 1,
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
      ),
      useMaterial3: true,
    );

    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        primary: primaryTeal,
        secondary: accentYellow,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF111827),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F2937),
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF1F2937),
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'TaskEngine',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeNotifier.isDark ? ThemeMode.dark : ThemeMode.light,
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
