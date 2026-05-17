import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../widgets/app_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _nameCtrl    = TextEditingController();
  bool _isLogin      = true;
  bool _obscure      = true;
  bool _loading      = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // Icon
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3949AB).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF3949AB).withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.apartment_rounded,
                      color: Color(0xFF7986CB), size: 28),
                ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),

                const SizedBox(height: 28),
                Text(
                  _isLogin
                      ? 'Sign in to\nyour community'
                      : 'Create your\naccount',
                  style: GoogleFonts.poppins(
                      fontSize: 32, fontWeight: FontWeight.w700,
                      color: Colors.white, height: 1.15),
                ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1, end: 0),

                const SizedBox(height: 6),
                Text('Apartment Secretary',
                    style: GoogleFonts.poppins(
                        color: const Color(0xFFFFB300), fontSize: 13,
                        fontWeight: FontWeight.w500))
                    .animate(delay: 200.ms).fadeIn(),

                const SizedBox(height: 40),

                // Name (sign up only)
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: _isLogin
                      ? const SizedBox.shrink()
                      : Column(children: [
                          AppField(
                            controller: _nameCtrl,
                            label: 'Full Name',
                            icon: Icons.person_outline_rounded,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Name is required'
                                : null,
                          ),
                          const SizedBox(height: 16),
                        ]),
                ),

                AppField(
                  controller: _emailCtrl,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ).animate(delay: 300.ms).fadeIn().slideX(begin: 0.05, end: 0),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (!_isLogin && v.length < 6) return 'Min 6 characters';
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle:
                        GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: Colors.white38, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white38, size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1A1A2E),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF5C6BC0), width: 1.5)),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Colors.redAccent, width: 1.5)),
                    focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Colors.redAccent, width: 1.5)),
                  ),
                ).animate(delay: 400.ms).fadeIn().slideX(begin: 0.05, end: 0),

                const SizedBox(height: 32),

                SubmitButton(
                  label: _isLogin ? 'Sign In' : 'Create Account',
                  loading: _loading,
                  onTap: _submit,
                ).animate(delay: 500.ms).fadeIn(),

                const SizedBox(height: 24),

                Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _isLogin = !_isLogin),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                            color: Colors.white38, fontSize: 13),
                        children: [
                          TextSpan(
                              text: _isLogin
                                  ? "Don't have an account? "
                                  : 'Already have an account? '),
                          TextSpan(
                            text: _isLogin ? 'Sign Up' : 'Sign In',
                            style: GoogleFonts.poppins(
                                color: const Color(0xFFFFB300),
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate(delay: 550.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      if (_isLogin) {
        await auth.signIn(
            email: _emailCtrl.text.trim(), password: _passCtrl.text);
      } else {
        await auth.signUp(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
            displayName: _nameCtrl.text.trim());
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
