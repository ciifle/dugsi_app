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
    // Simulate splash screen delay
    await Future.delayed(const Duration(seconds: 2));

    final loggedIn = await isLoggedIn();
    print('🔐 AppStartRouter - isLoggedIn: $loggedIn');

    setState(() {
      if (loggedIn) {
        _startScreen = const RoleRouter();
      } else {
        _startScreen = const LoginPage();
      }
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
    try {
      final user = await LocalAuthService().getCurrentUser();
      print('👤 Current user: ${user?.email}, Role: ${user?.role}');
      return user?.role;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserRole?>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (snapshot.hasError) {
          print('Error in RoleRouter: ${snapshot.error}');
          return const LoginPage();
        }

        if (!snapshot.hasData || snapshot.data == null) {
          print('No user data found, redirecting to login');
          return const LoginPage();
        }

        final userRole = snapshot.data;
        print('Routing to role: $userRole');

        // Navigate based on role
        switch (userRole) {
          case UserRole.student:
            return const StudentDashboardScreen();
          case UserRole.parent:
            return const ParentDashboardScreen();
          case UserRole.teacher:
            return const TeacherDashboardScreen();
          case UserRole.schoolAdmin:
            return const SchoolAdminScreen();
          default:
            print('Unknown role: $userRole');
            return const LoginPage();
        }
      },
    );
  }
}
