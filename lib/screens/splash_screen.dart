import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import 'login_screen.dart';
import 'student_dashboard.dart';
import 'admin_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
    _boot();
  }

  Future<void> _boot() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    await context.read<AppProvider>().tryAutoLogin();
    if (!mounted) return;
    final status = context.read<AppProvider>().authStatus;
    if (status == AuthStatus.authenticated) {
      _navigate();
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  void _navigate() {
    final provider = context.read<AppProvider>();
    Widget dest = provider.isAdmin ? const AdminDashboard() : const StudentDashboard();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => dest));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB71C1C), Color(0xFFD32F2F), Color(0xFFEF5350)],
          ),
        ),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.school, size: 56, color: Color(0xFFD32F2F)),
                ),
                const SizedBox(height: 24),
                const Text('College SOS', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 8),
                const Text('Student Safety & Support Platform', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 48),
                const CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
