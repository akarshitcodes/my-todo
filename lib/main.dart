import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/app_preferences.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final initialThemeMode =
      await AppPreferences.instance.getThemeMode();

  await NotificationService.instance.initialize();

  runApp(
    TodoApp(
      initialThemeMode: initialThemeMode,
    ),
  );
}

class TodoApp extends StatefulWidget {
  final ThemeMode initialThemeMode;

  const TodoApp({
    super.key,
    required this.initialThemeMode,
  });

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
  }

  Future<void> _changeThemeMode(ThemeMode mode) async {
    setState(() {
      _themeMode = mode;
    });

    await AppPreferences.instance.setThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My To-Do',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      themeAnimationDuration: const Duration(
        milliseconds: 350,
      ),
      themeAnimationCurve: Curves.easeInOut,
      home: SplashScreen(
        nextScreen: HomeScreen(
          themeMode: _themeMode,
          onThemeModeChanged: _changeThemeMode,
        ),
      ),
    );
  }
}