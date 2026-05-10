// lib/screens/home/security_home_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class SecurityHomeScreen extends StatelessWidget {
  const SecurityHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentAppUser;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12122A),
        title: Text(
          'Security Panel',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.read<AuthService>().signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.security_rounded,
                size: 64, color: Color(0xFF26A69A)),
            const SizedBox(height: 16),
            Text(
              'Welcome, ${user?.displayName ?? 'Guard'}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Security Dashboard — build your features here.',
              style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
