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

  static const _roles = [
    _RoleOption(
      role: UserRole.resident,
      label: 'Resident',
      subtitle: 'Manage your flat, visitors & parcels',
      icon: Icons.home_rounded,
      color: Color(0xFF5C6BC0), // indigo-400
    ),
    _RoleOption(
      role: UserRole.secretary,
      label: 'Secretary',
      subtitle: 'Oversee community, notices & issues',
      icon: Icons.admin_panel_settings_rounded,
      color: Color(0xFFFFB300), // amber-600
    ),
    _RoleOption(
      role: UserRole.security,
      label: 'Security Guard',
      subtitle: 'Log visitors, parcels & gate access',
      icon: Icons.security_rounded,
      color: Color(0xFF26A69A), // teal-400
    ),
  ];

  Future<void> _confirm() async {
    if (_selected == null) return;
    setState(() => _saving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await context.read<AuthService>().saveUserRole(uid, _selected!);
      // main.dart's StreamBuilder will automatically route after role is saved.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save role. Try again.\n$e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              Text(
                'Who are\nyou?',
                style: GoogleFonts.poppins(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.1,
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: -0.2, end: 0),
              const SizedBox(height: 8),
              Text(
                'Select your role in the community.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white38,
                ),
              )
                  .animate(delay: 150.ms)
                  .fadeIn(duration: 400.ms),
              const SizedBox(height: 48),

              // ── Role Cards ──────────────────────────────────────────
              Expanded(
                child: ListView.separated(
                  itemCount: _roles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final option = _roles[index];
                    final isSelected = _selected == option.role;
                    return _RoleCard(
                      option: option,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selected = option.role),
                    )
                        .animate(delay: (200 + index * 100).ms)
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: 0.15, end: 0);
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ── Confirm Button ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_selected != null && !_saving) ? _confirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          'Continue',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ).animate(delay: 600.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.read<AuthService>().signOut(),
                  child: Text(
                    'Sign out',
                    style: GoogleFonts.poppins(
                      color: Colors.white30,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _RoleOption {
  final UserRole role;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _RoleOption({
    required this.role,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

// ── Card Widget ───────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final _RoleOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected
            ? option.color.withOpacity(0.15)
            : const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? option.color : Colors.white10,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: option.color.withOpacity(isSelected ? 0.25 : 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    option.icon,
                    color: option.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.label,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        option.subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
                // Check
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isSelected ? 1.0 : 0.0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: option.color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
