import 'package:flutter/material.dart';
import 'package:kobac/models/dummy_user.dart';
import 'package:kobac/school_admin/pages/school_admin_screen.dart';
import 'package:kobac/services/local_auth_service.dart';
import 'package:kobac/student/pages/student_dashboard.dart';
import 'package:kobac/teacher/pages/teacher_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _loginError;
  bool _isLoading = false;

  late AnimationController _topCircleController;
  late Animation<Offset> _topCircleOffset;
  late AnimationController _bottomCircleController;
  late Animation<Offset> _bottomCircleOffset;

  @override
  void initState() {
    super.initState();
    _topCircleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _topCircleOffset =
        Tween<Offset>(begin: const Offset(0.8, -1.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _topCircleController,
            curve: Curves.easeOutCubic,
          ),
        );

    _bottomCircleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _bottomCircleOffset =
        Tween<Offset>(
          begin: const Offset(-1.05, 1.2),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _bottomCircleController,
            curve: Curves.easeOutCubic,
          ),
        );

    _topCircleController.forward();
    _bottomCircleController.forward();
  }

  @override
  void dispose() {
    _topCircleController.dispose();
    _bottomCircleController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login(BuildContext context) async {
    setState(() {
      _loginError = null;
      _isLoading = true;
    });

    final identifier = _emailController.text.trim();
    final password = _passwordController.text;

    final user = await LocalAuthService().login(identifier, password);

    setState(() {
      _isLoading = false;
    });

    if (user != null) {
      Widget targetScreen;
      switch (user.role) {
        case UserRole.schoolAdmin:
          targetScreen = const SchoolAdminScreen();
          break;
        case UserRole.teacher:
          targetScreen = TeacherDashboardScreen();
          break;
        case UserRole.student:
          targetScreen = StudentDashboardScreen();
          break;
        case UserRole.parent: // Added parent handling
          targetScreen = const Scaffold(
            body: Center(child: Text("Parent Dashboard Placeholder")),
          ); // TODO: Create Parent Dashboard
          break;
        default:
          setState(() {
            _loginError = "Unknown user role.";
          });
          return;
      }
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => targetScreen));
    } else {
      setState(() {
        _loginError = 'Invalid email or password.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final offWhite = Colors.grey[300];
    final orange = const Color(0xFF5AB04B);
    final darkBlue = const Color(0xFF023471);

    final double cardWidth = MediaQuery.of(context).size.width * 0.88;
    final double circleDiameter = MediaQuery.of(context).size.width * 0.55;
    final double circleBorderWidth = 22;

    return Scaffold(
      backgroundColor: offWhite,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -circleDiameter * 0.45,
              right: -circleDiameter * 0.4,
              child: SlideTransition(
                position: _topCircleOffset,
                child: Container(
                  width: circleDiameter,
                  height: circleDiameter,
                  decoration: BoxDecoration(
                    color: orange,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: darkBlue,
                      width: circleBorderWidth,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -circleDiameter * 0.45,
              left: -circleDiameter * 0.4,
              child: SlideTransition(
                position: _bottomCircleOffset,
                child: Container(
                  width: circleDiameter,
                  height: circleDiameter,
                  decoration: BoxDecoration(
                    color: orange,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: darkBlue,
                      width: circleBorderWidth,
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  width: cardWidth,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade500,
                        offset: const Offset(4.0, 4.0),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.white,
                        offset: const Offset(-4.0, -4.0),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Login",
                          style: TextStyle(
                            color: darkBlue,
                            fontSize: 35,
                            fontWeight: FontWeight.w700,
                            fontFamily: Theme.of(
                              context,
                            ).textTheme.titleLarge?.fontFamily,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Email / ID',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E4EC),
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E4EC),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: darkBlue,
                                width: 1.8,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: TextStyle(fontSize: 16, color: darkBlue),
                          autofillHints: const [
                            AutofillHints.username,
                            AutofillHints.email,
                          ],
                          validator: (value) => value == null || value.isEmpty
                              ? "Please enter your email/ID"
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E4EC),
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E4EC),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: darkBlue,
                                width: 1.8,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: TextStyle(fontSize: 16, color: darkBlue),
                          autofillHints: const [AutofillHints.password],
                          validator: (value) => value == null || value.isEmpty
                              ? "Please enter your password"
                              : null,
                        ),
                        if (_loginError != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _loginError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 15,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: darkBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 1,
                              shadowColor: darkBlue.withOpacity(0.10),
                              textStyle: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: _isLoading
                                ? null
                                : () {
                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      _login(context);
                                    }
                                  },
                            child: _isLoading
                                ? const SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
