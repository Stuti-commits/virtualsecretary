import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final auth = context.read<AuthService>();
      if (_isLogin) {
        await auth.signIn(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      } else {
        await auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          displayName: _nameCtrl.text.trim(),
        );
      }
      // Navigation is handled by StreamBuilder in main.dart
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

                // ── Logo / Title ────────────────────────────────────
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3949AB).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF3949AB).withOpacity(0.4)),
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    color: Color(0xFF7986CB),
                    size: 28,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(begin: const Offset(0.8, 0.8)),

                const SizedBox(height: 28),

                Text(
                  _isLogin ? 'Sign in to\nyour community' : 'Create your\naccount',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.15,
                  ),
                )
                    .animate(delay: 100.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 8),
                Text(
                  'Apartment Secretary',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFFFB300),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate(delay: 200.ms).fadeIn(),

                const SizedBox(height: 40),

                // ── Name field (sign up only) ───────────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: _isLogin
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            _AppTextField(
                              controller: _nameCtrl,
                              label: 'Full Name',
                              icon: Icons.person_outline_rounded,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Enter your name'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                ),

                // ── Email ───────────────────────────────────────────
                _AppTextField(
                  controller: _emailCtrl,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                )
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 350.ms)
                    .slideX(begin: 0.05, end: 0),

                const SizedBox(height: 16),

                // ── Password ────────────────────────────────────────
                _AppTextField(
                  controller: _passwordCtrl,
                  label: 'Password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white38,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your password';
                    if (!_isLogin && v.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 350.ms)
                    .slideX(begin: 0.05, end: 0),

                const SizedBox(height: 32),

                // ── Submit Button ───────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3949AB),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isLogin ? 'Sign In' : 'Create Account',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ).animate(delay: 500.ms).fadeIn(duration: 350.ms),

                const SizedBox(height: 24),

                // ── Toggle ──────────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _isLogin = !_isLogin),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                        children: [
                          TextSpan(
                            text: _isLogin
                                ? "Don't have an account? "
                                : 'Already have an account? ',
                          ),
                          TextSpan(
                            text: _isLogin ? 'Sign Up' : 'Sign In',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFFFB300),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
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
}

// ── Reusable text field ───────────────────────────────────────────────────────

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _AppTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.poppins(color: Colors.white38, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF5C6BC0), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle:
            GoogleFonts.poppins(color: Colors.redAccent, fontSize: 11),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}
