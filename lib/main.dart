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
        title: 'Dugsi',
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
/// SPLASH only on cold start (first open / restart), not between pages
/// =========================

bool _splashShownThisSession = false;

class AppStartRouter extends StatefulWidget {
  const AppStartRouter({super.key});

  @override
  State<AppStartRouter> createState() => _AppStartRouterState();
}

class _AppStartRouterState extends State<AppStartRouter> {
  bool _initStarted = false;
  bool _splashMinTimeReached = false;
  static const Duration _splashMinDuration = Duration(seconds: 5);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initStarted) {
      _initStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AuthProvider>().initializeAuth();
      });
      // Only run splash timer on cold start (splash not yet shown this session)
      if (!_splashShownThisSession) {
        Future.delayed(_splashMinDuration, () {
          if (mounted) {
            _splashShownThisSession = true;
            setState(() => _splashMinTimeReached = true);
          }
        });
      } else {
        // Splash already shown this session (e.g. came back from login): skip splash
        _splashMinTimeReached = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Show splash only on cold start (first time this session), for 5s
        final showSplash = !_splashShownThisSession && (!_splashMinTimeReached || auth.isLoading);
        if (showSplash) {
          return const SplashScreen();
        }
        if (!auth.isAuthenticated) {
          return const LoginPage();
        }
        return roleToHome(auth.user);
      },
    );
  }
}
