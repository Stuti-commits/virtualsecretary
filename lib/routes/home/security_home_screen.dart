import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/parcel_model.dart';
import '../../models/visitor_model.dart';
import '../../services/auth_service.dart';
import '../../services/community_service.dart';
import '../../widgets/app_widgets.dart';

class SecurityHomeScreen extends StatefulWidget {
  const SecurityHomeScreen({super.key});

  @override
  State<SecurityHomeScreen> createState() => _SecurityHomeScreenState();
}

class _SecurityHomeScreenState extends State<SecurityHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentAppUser;
    final uid  = user?.uid ?? '';
    final svc  = CommunityService();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12122A),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gate Control',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            Text(user?.displayName ?? 'Security',
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
      body: _tab == 0
          ? _ParcelsPanel(svc: svc, guardUid: uid)
          : _VisitorsPanel(svc: svc, guardUid: uid),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF12122A),
        indicatorColor: const Color(0xFF26A69A).withOpacity(0.25),
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon:
                Icon(Icons.inventory_2_rounded, color: Color(0xFF26A69A)),
            label: 'Parcels',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon:
                Icon(Icons.people_rounded, color: Color(0xFF26A69A)),
            label: 'Visitors',
          ),
        ],
      ),
    );
  }
}

// ── Parcels panel ─────────────────────────────────────────────────────────────

class _ParcelsPanel extends StatelessWidget {
  final CommunityService svc;
  final String guardUid;
  const _ParcelsPanel({required this.svc, required this.guardUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ParcelModel>>(
      stream: svc.streamActiveParcels(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF26A69A)));
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.inventory_2_outlined,
            message: 'No active parcels at the gate.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) =>
              _SecurityParcelCard(parcel: list[i], svc: svc, guardUid: guardUid),
        );
      },
    );
  }
}

class _SecurityParcelCard extends StatelessWidget {
  final ParcelModel parcel;
  final CommunityService svc;
  final String guardUid;
  const _SecurityParcelCard(
      {required this.parcel, required this.svc, required this.guardUid});

  @override
  Widget build(BuildContext context) {
    final arrived = parcel.status == ParcelStatus.arrived;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: arrived
              ? const Color(0xFFFFB300).withOpacity(0.5)
              : Colors.white10,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(children: [
          Icon(_icon(parcel.type), color: const Color(0xFF26A69A), size: 20),
          const SizedBox(width: 8),
          Text(parcel.type.label,
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
          const Spacer(),
          if (arrived)
            StatusBadge(label: 'ARRIVED', color: const Color(0xFFFFB300)),
        ]),
        const SizedBox(height: 10),
        InfoRow(
          icon: Icons.person_outline_rounded,
          text: '${parcel.residentName}  ·  Flat ${parcel.flatNumber}',
        ),
        const SizedBox(height: 4),
        InfoRow(
          icon: parcel.deliveryToDoor
              ? Icons.door_front_door_outlined
              : Icons.security_outlined,
          text: parcel.deliveryToDoor ? 'Deliver to door' : 'Leave at gate',
        ),
        const SizedBox(height: 4),
        InfoRow(
          icon: Icons.calendar_today_outlined,
          text: 'Expected: ${DateFormat('dd MMM').format(parcel.expectedDate)}',
        ),
        const SizedBox(height: 14),
        if (!arrived)
          ActionBtn(
            label: '✓  Mark Arrived',
            color: const Color(0xFFFFB300),
            onTap: () => svc.markParcelArrived(parcel.id, guardUid),
          )
        else
          ActionBtn(
            label: '✓  Mark Collected',
            color: Colors.green,
            onTap: () => svc.markParcelCollected(parcel.id),
          ),
      ]),
    );
  }

  IconData _icon(ParcelType t) {
    switch (t) {
      case ParcelType.amazon:  return Icons.shopping_bag_outlined;
      case ParcelType.blinkit: return Icons.flash_on_rounded;
      case ParcelType.swiggy:  return Icons.fastfood_outlined;
      case ParcelType.other:   return Icons.inventory_outlined;
    }
  }
}

// ── Visitors panel ────────────────────────────────────────────────────────────

class _VisitorsPanel extends StatelessWidget {
  final CommunityService svc;
  final String guardUid;
  const _VisitorsPanel({required this.svc, required this.guardUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VisitorModel>>(
      stream: svc.streamTodayVisitors(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF26A69A)));
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.people_outline_rounded,
            message: 'No visitors expected today.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) =>
              _SecurityVisitorCard(visitor: list[i], svc: svc, guardUid: guardUid),
        );
      },
    );
  }
}

class _SecurityVisitorCard extends StatelessWidget {
  final VisitorModel visitor;
  final CommunityService svc;
  final String guardUid;
  const _SecurityVisitorCard(
      {required this.visitor, required this.svc, required this.guardUid});

  @override
  Widget build(BuildContext context) {
    final inside = visitor.status == VisitorStatus.checkedIn;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: inside
              ? const Color(0xFFFFB300).withOpacity(0.4)
              : Colors.white10,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF26A69A).withOpacity(0.15),
            child: Text(
              visitor.name.isNotEmpty ? visitor.name[0].toUpperCase() : '?',
              style: GoogleFonts.poppins(
                  color: const Color(0xFF26A69A),
                  fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(visitor.name,
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w600,
                      fontSize: 15)),
              Text(visitor.phone,
                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
            ]),
          ),
          if (inside)
            const StatusBadge(label: 'INSIDE', color: Color(0xFFFFB300)),
        ]),
        const SizedBox(height: 10),
        InfoRow(
          icon: Icons.apartment_outlined,
          text: '${visitor.residentName}  ·  Flat ${visitor.flatNumber}',
        ),
        const SizedBox(height: 4),
        InfoRow(
          icon: Icons.access_time_rounded,
          text: 'Expected: ${DateFormat('h:mm a').format(visitor.expectedTime)}',
        ),
        if (visitor.purposeNote.isNotEmpty) ...[
          const SizedBox(height: 4),
          InfoRow(icon: Icons.notes_rounded, text: visitor.purposeNote),
        ],
        const SizedBox(height: 14),
        if (!inside)
          ActionBtn(
            label: '→  Check In',
            color: const Color(0xFF26A69A),
            onTap: () => svc.markCheckedIn(visitor.id, guardUid),
          )
        else
          ActionBtn(
            label: '←  Check Out',
            color: Colors.redAccent,
            onTap: () => svc.markCheckedOut(visitor.id),
          ),
      ]),
    );
  }
}
