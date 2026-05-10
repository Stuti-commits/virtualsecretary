// lib/screens/home/secretary_home_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class SecretaryHomeScreen extends StatelessWidget {
  const SecretaryHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentAppUser;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12122A),
        title: Text(
          'Secretary Panel',
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
            const Icon(Icons.admin_panel_settings_rounded,
                size: 64, color: Color(0xFFFFB300)),
            const SizedBox(height: 16),
            Text(
              'Welcome, ${user?.displayName ?? 'Secretary'}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Secretary Dashboard — build your features here.',
              style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
