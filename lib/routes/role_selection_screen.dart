import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selected;
  bool _saving = false;

  static const _options = [
    _RoleOpt(
      role: UserRole.resident,
      label: 'Resident',
      subtitle: 'Manage parcels, visitors & issues',
      icon: Icons.home_rounded,
      color: Color(0xFF5C6BC0),
    ),
    _RoleOpt(
      role: UserRole.secretary,
      label: 'Secretary',
      subtitle: 'Oversee community, notices & issues',
      icon: Icons.admin_panel_settings_rounded,
      color: Color(0xFFFFB300),
    ),
    _RoleOpt(
      role: UserRole.security,
      label: 'Security Guard',
      subtitle: 'Log visitors, parcels & gate access',
      icon: Icons.security_rounded,
      color: Color(0xFF26A69A),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Who are\nyou?',
                  style: GoogleFonts.poppins(
                      fontSize: 40, fontWeight: FontWeight.w700,
                      color: Colors.white, height: 1.1))
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.15, end: 0),

              const SizedBox(height: 8),
              Text('Select your role in the community.',
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.white38))
                  .animate(delay: 150.ms).fadeIn(),

              const SizedBox(height: 48),

              Expanded(
                child: ListView.separated(
                  itemCount: _options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, i) {
                    final opt = _options[i];
                    return _RoleCard(
                      opt: opt,
                      selected: _selected == opt.role,
                      onTap: () => setState(() => _selected = opt.role),
                    )
                        .animate(delay: (200 + i * 100).ms)
                        .fadeIn(duration: 350.ms)
                        .slideX(begin: 0.1, end: 0);
                  },
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      (_selected != null && !_saving) ? _confirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white12,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 22, width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.black))
                      : Text('Continue',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ).animate(delay: 600.ms).fadeIn(),

              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () =>
                      context.read<AuthService>().signOut(),
                  child: Text('Sign out',
                      style: GoogleFonts.poppins(
                          color: Colors.white30, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    if (_selected == null) return;
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await context.read<AuthService>().saveUserRole(uid, _selected!);
      // Consumer in _AuthRouter will rebuild automatically
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to save role: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _RoleOpt {
  final UserRole role;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _RoleOpt({
    required this.role, required this.label, required this.subtitle,
    required this.icon, required this.color,
  });
}

class _RoleCard extends StatelessWidget {
  final _RoleOpt opt;
  final bool selected;
  final VoidCallback onTap;
  const _RoleCard(
      {required this.opt, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: selected
            ? opt.color.withValues(alpha :0.12)
            : const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? opt.color : Colors.white10,
          width: selected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: opt.color.withValues(alpha :selected ? 0.22 : 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(opt.icon, color: opt.color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(opt.label,
                        style: GoogleFonts.poppins(
                            fontSize: 17, fontWeight: FontWeight.w600,
                            color: Colors.white)),
                    const SizedBox(height: 3),
                    Text(opt.subtitle,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.white38)),
                  ],
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: selected ? 1.0 : 0.0,
                child: Container(
                  width: 24, height: 24,
                  decoration:
                      BoxDecoration(color: opt.color, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 14, color: Colors.black),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
