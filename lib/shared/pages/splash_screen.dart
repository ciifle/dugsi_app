import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // One cycle = zoom in then zoom out (5 seconds)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    // Zoom in: small → big, then zoom out: big → small (single cycle)
    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 1.6)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.6, end: 0.9)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 50,
      ),
    ]).animate(_controller);

    _controller.forward();
    // Router keeps this screen visible for 11s, then switches to login/home
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Center(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.scale(
                scale: _animation.value,
                alignment: Alignment.center,
                child: child,
              );
            },
            child: Image.asset(
              "assets/splash_image.png",
              width: 280,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.school_rounded, size: 80, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }
}
