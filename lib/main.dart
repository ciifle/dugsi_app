import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:kobac/services/auth_provider.dart';
import 'package:kobac/shared/pages/login_screen.dart';
import 'package:kobac/shared/pages/splash_screen.dart';

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
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'kobac',
        debugShowCheckedModeBanner: false,
        navigatorKey: authNavigatorKey,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AppStartRouter(),
          '/login': (context) => const LoginPage(),
        },
      ),
    );
  }
}

/// =========================
/// SPLASH → LOGIN / ROLE HOME
/// =========================

class AppStartRouter extends StatefulWidget {
  const AppStartRouter({super.key});

  @override
  State<AppStartRouter> createState() => _AppStartRouterState();
}

class _AppStartRouterState extends State<AppStartRouter> {
  bool _initStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initStarted) {
      _initStarted = true;
      // Defer so we don't call notifyListeners() during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AuthProvider>().initializeAuth();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const SplashScreen();
        }
        // Route guard: not authenticated -> only Login
        if (!auth.isAuthenticated) {
          return const LoginPage();
        }
        // Authenticated -> role-based home (block back to Login until logout)
        return roleToHome(auth.user);
      },
    );
  }
}
