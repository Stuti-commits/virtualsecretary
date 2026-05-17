import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import 'tabs/resident_parcels_tab.dart';
import 'tabs/resident_visitors_tab.dart';
import 'tabs/resident_issues_tab.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tabs/notification_screen.dart';

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
  void initState() {
    super.initState();

    _setupNotifications();
  }

  Future<void> _setupNotifications() async {
    final user = context.read<AuthService>().currentAppUser;

    if (user != null) {
      await NotificationService.instance.syncSubscriptions(user);
    }
  }


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
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .collection('notifications')
                .where('read', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final unread = snapshot.data?.docs.length ?? 0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NotificationsScreen(
                            userId: user!.uid,
                          ),
                        ),
                      );
                    },
                  ),

                  if (unread > 0)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unread.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: () => context.read<AuthService>().signOut(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: _tabs,
      ),
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
