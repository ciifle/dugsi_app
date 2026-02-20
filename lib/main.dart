import 'package:flutter/material.dart';
import 'package:kobac/models/dummy_user.dart';
import 'package:kobac/parent/pages/parent_dashboard.dart';
import 'package:kobac/school_admin/pages/school_admin_screen.dart';
import 'package:kobac/services/local_auth_service.dart';
import 'package:kobac/shared/pages/login_screen.dart';
import 'package:kobac/shared/pages/splash_screen.dart';
import 'package:kobac/student/pages/student_dashboard.dart';
import 'package:kobac/teacher/pages/teacher_dashboard.dart';

/// =========================
/// AUTH UTILITIES
/// =========================

Future<bool> isLoggedIn() async {
  final user = await LocalAuthService().getCurrentUser();
  return user != null;
}

Future<void> logout() async {
  await LocalAuthService().logout();
}

/// =========================
/// ENTRY POINT
/// =========================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppRoot());
}

/// =========================
/// ROOT APP
/// =========================

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kobac',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AppStartRouter(),
    );
  }
}

/// =========================
/// SPLASH → LOGIN / HOME ROUTER
/// =========================

class AppStartRouter extends StatefulWidget {
  const AppStartRouter({super.key});

  @override
  State<AppStartRouter> createState() => _AppStartRouterState();
}

class _AppStartRouterState extends State<AppStartRouter> {
  bool _initialized = false;
  Widget? _startScreen;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(seconds: 2)); // splash delay

    final loggedIn = await isLoggedIn();

    setState(() {
      _startScreen = loggedIn ? const RoleRouter() : const LoginPage();
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const SplashScreen();
    }
    return _startScreen!;
  }
}

/// =========================
/// ROLE ROUTER
/// =========================

class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  late Future<UserRole?> _roleFuture;

  @override
  void initState() {
    super.initState();
    _roleFuture = _getRole();
  }

  Future<UserRole?> _getRole() async {
    final user = await LocalAuthService().getCurrentUser();
    return user?.role;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserRole?>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const LoginPage();
        }

        if (!snapshot.hasData) {
          return const SplashScreen();
        }

        switch (snapshot.data) {
          case UserRole.student:
            return StudentDashboardScreen();
          case UserRole.parent:
            return const ParentDashboardScreen();
          case UserRole.teacher:
            return TeacherDashboardScreen();
          case UserRole.schoolAdmin:
            return const SchoolAdminScreen();
          default:
            return const LoginPage();
        }
      },
    );
  }
}
