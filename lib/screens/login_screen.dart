import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../services/api_service.dart';
import 'student_dashboard.dart';
import 'admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _rollCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  String _selectedRole = 'student';
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _rollCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AppProvider>().login(
        _rollCtrl.text.trim(),
        _passCtrl.text.trim(),
        _selectedRole,
      );
      if (!mounted) return;
      final provider = context.read<AppProvider>();
      Widget dest = provider.isAdmin ? const AdminDashboard() : const StudentDashboard();
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => dest));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Connection error. Is the server running?');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 14, offset: const Offset(0, 5))]),
                    child: const Icon(Icons.school, size: 44, color: Color(0xFFD32F2F)),
                  ),
                  const SizedBox(height: 18),
                  const Text('College SOS', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  const Text('Student Safety & Support Platform', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 36),

                  // Role selector
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: ['student', 'admin'].map((role) {
                        final selected = _selectedRole == role;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _selectedRole = role;
                              _rollCtrl.clear();
                              _passCtrl.clear();
                              _error = null;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selected ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(role == 'student' ? Icons.person : Icons.admin_panel_settings,
                                      size: 16, color: selected ? const Color(0xFFD32F2F) : Colors.white70),
                                  const SizedBox(width: 6),
                                  Text(role == 'student' ? 'Student' : 'Admin',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 13,
                                          color: selected ? const Color(0xFFD32F2F) : Colors.white70)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selectedRole == 'student' ? 'Roll Number' : 'Admin ID',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _rollCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: _inputDec(
                              hint: _selectedRole == 'student' ? 'e.g. 2023CS001' : 'e.g. ADMIN001',
                              icon: Icons.badge_outlined,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            decoration: _inputDec(hint: 'Enter password', icon: Icons.lock_outline).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(8)),
                              child: Row(children: [
                                const Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 13))),
                              ]),
                            ),
                          ],
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity, height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedRole == 'admin' ? const Color(0xFF1565C0) : const Color(0xFFD32F2F),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _loading ? null : _login,
                              child: _loading
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : Text(_selectedRole == 'admin' ? 'Admin Login' : 'Login',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Demo hints
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        const Text('Demo Credentials', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),
                        const Text('Students', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        const SizedBox(height: 4),
                        _credRow('2023CS001', 'pass123'),
                        _credRow('2023CS002', 'pass456'),
                        _credRow('2022EC010', 'pass789'),
                        const SizedBox(height: 6),
                        const Text('Admin', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        const SizedBox(height: 4),
                        _credRow('ADMIN001', 'admin123'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _credRow(String id, String pass) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(id, style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace')),
      const Text(' / ', style: TextStyle(color: Colors.white54, fontSize: 12)),
      Text(pass, style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace')),
    ]),
  );

  InputDecoration _inputDec({required String hint, required IconData icon}) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
    prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade600),
    filled: true, fillColor: Colors.grey.shade50,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
  );
}
