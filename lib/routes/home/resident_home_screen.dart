import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import 'tabs/resident_parcels_tab.dart';
import 'tabs/resident_visitors_tab.dart';
import 'tabs/resident_issues_tab.dart';

class ResidentHomeScreen extends StatefulWidget {
  const ResidentHomeScreen({super.key});

  @override
  State<ResidentHomeScreen> createState() => _ResidentHomeScreenState();
}

class _ResidentHomeScreenState extends State<ResidentHomeScreen> {
  int _tab = 0;

  static const _tabs = [
    ResidentParcelsTab(),
    ResidentVisitorsTab(),
    ResidentIssuesTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentAppUser;
    final first = user?.displayName.split(' ').first ?? 'Resident';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12122A),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, $first 👋',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            Text('Resident',
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
        indicatorColor: const Color(0xFF3949AB).withValues(alpha: 0.3),
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon:
                Icon(Icons.inventory_2_rounded, color: Color(0xFF7986CB)),
            label: 'Parcels',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon:
                Icon(Icons.people_rounded, color: Color(0xFF7986CB)),
            label: 'Visitors',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon:
                Icon(Icons.build_rounded, color: Color(0xFF7986CB)),
            label: 'Issues',
          ),
        ],
      ),
    );
  }
}
