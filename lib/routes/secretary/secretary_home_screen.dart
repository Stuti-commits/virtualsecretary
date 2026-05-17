import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';

// existing issues tab (already built)
import '../home/secretary_issues_tab.dart';

// new tabs
import 'tabs/meetings_tab.dart';
import 'tabs/fees_tab.dart';

class SecretaryHomeScreen extends StatefulWidget {
  const SecretaryHomeScreen({super.key});

  @override
  State<SecretaryHomeScreen> createState() => _SecretaryHomeScreenState();
}

class _SecretaryHomeScreenState extends State<SecretaryHomeScreen> {
  int _tab = 0;

  static const _tabs = [
    SecretaryIssuesTab(),  // maintenance issues (existing)
    MeetingsTab(),         // community meetings  (new)
    FeesTab(),             // fee collection      (new)
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentAppUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12122A),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Secretary Panel',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            Text(user?.displayName ?? '',
                style:
                    GoogleFonts.poppins(fontSize: 11, color: Colors.white38)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: () => context.read<AuthService>().signOut(),
          ),
        ],
      ),
      body: _tabs[_tab],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF12122A),
        indicatorColor: const Color(0xFFFFB300).withOpacity(0.2),
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon:
                Icon(Icons.build_rounded, color: Color(0xFFFFB300)),
            label: 'Issues',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon:
                Icon(Icons.event_rounded, color: Color(0xFFFFB300)),
            label: 'Meetings',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon:
                Icon(Icons.receipt_long_rounded, color: Color(0xFFFFB300)),
            label: 'Fees',
          ),
        ],
      ),
    );
  }
}
