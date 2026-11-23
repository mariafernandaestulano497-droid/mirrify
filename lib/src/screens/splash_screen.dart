import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/mirrify_logo.dart';
import '../supabase_client.dart';
import 'login_page.dart';
import 'simulator_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();

    // Após 2.6s decide para onde navegar:
    // - Se usuário já está logado → SimulatorPage
    // - Caso contrário → LoginPage
    Future.delayed(const Duration(milliseconds: 2600), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    final hasSession = SupabaseService.currentUser != null;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, anim, __) =>
            hasSession ? const SimulatorPage() : const LoginPage(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MirrifyBackground(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: const MirrifyBrandHeader(
                starSize: 72,
                titleSize: 34,
                showSubtitle: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
