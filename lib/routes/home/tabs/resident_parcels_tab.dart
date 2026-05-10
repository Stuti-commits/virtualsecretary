import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/parcel_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/community_service.dart';
import '../../../widgets/app_widgets.dart';

class ResidentParcelsTab extends StatelessWidget {
  const ResidentParcelsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentAppUser!;
    final svc  = CommunityService();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFFB300),
        foregroundColor: Colors.black,
        icon:  const Icon(Icons.add),
        label: Text('Expect Parcel',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        onPressed: () => _openSheet(context, user, svc),
      ),
      body: StreamBuilder<List<ParcelModel>>(
        stream: svc.streamMyParcels(user.uid),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF7986CB)));
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              message: 'No parcels yet.\nTap + to register an expected delivery.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _ParcelCard(parcel: list[i]),
          );
        },
      ),
    );
  }

  void _openSheet(BuildContext ctx, AppUser user, CommunityService svc) =>
      showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _RegisterSheet(user: user, svc: svc),
      );
}

// ── Parcel card ───────────────────────────────────────────────────────────────

class _ParcelCard extends StatelessWidget {
  final ParcelModel parcel;
  const _ParcelCard({required this.parcel});

  @override
  Widget build(BuildContext context) {
    final color = _color(parcel.status);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(_icon(parcel.type), color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(parcel.type.label,
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.w600,
                        fontSize: 15)),
                const SizedBox(height: 3),
                Text(
                  'Expected ${DateFormat('dd MMM').format(parcel.expectedDate)}'
                  '  ·  ${parcel.deliveryToDoor ? 'To door' : 'Gate drop'}',
                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          StatusBadge(label: _label(parcel.status), color: color),
        ],
      ),
    );
  }

  Color  _color(ParcelStatus s) {
    switch (s) {
      case ParcelStatus.expected:  return const Color(0xFF7986CB);
      case ParcelStatus.arrived:   return const Color(0xFFFFB300);
      case ParcelStatus.collected: return Colors.green;
    }
  }

  String _label(ParcelStatus s) {
    switch (s) {
      case ParcelStatus.expected:  return 'Expected';
      case ParcelStatus.arrived:   return 'Arrived!';
      case ParcelStatus.collected: return 'Collected';
    }
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

// ── Register sheet ────────────────────────────────────────────────────────────

class _RegisterSheet extends StatefulWidget {
  final AppUser user;
  final CommunityService svc;
  const _RegisterSheet({required this.user, required this.svc});

  @override
  State<_RegisterSheet> createState() => _RegisterSheetState();
}

class _RegisterSheetState extends State<_RegisterSheet> {
  ParcelType _type      = ParcelType.amazon;
  DateTime   _date      = DateTime.now().add(const Duration(days: 1));
  bool       _toDoor    = true;
  bool       _saving    = false;

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHeader(title: 'Register Expected Parcel'),

          // ── Delivery type ──────────────────────────────────────
          _SectionLabel('Delivery Type'),
          const SizedBox(height: 10),
          Row(
            children: ParcelType.values.map((t) {
              final sel = _type == t;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: sel
                          ? const Color(0xFF3949AB)
                          : const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel
                              ? const Color(0xFF7986CB)
                              : Colors.white12),
                    ),
                    child: Column(
                      children: [
                        Icon(_icon(t), size: 20,
                            color: sel ? Colors.white : Colors.white38),
                        const SizedBox(height: 4),
                        Text(t.label,
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: sel ? Colors.white : Colors.white38,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // ── Expected date ──────────────────────────────────────
          _SectionLabel('Expected Date'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: _DateTile(date: _date),
          ),
          const SizedBox(height: 20),

          // ── Delivery preference ────────────────────────────────
          _SectionLabel('Delivery Preference'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: _PrefTile(
                label: 'To My Door',
                icon: Icons.door_front_door_outlined,
                selected: _toDoor,
                onTap: () => setState(() => _toDoor = true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PrefTile(
                label: 'Leave at Gate',
                icon: Icons.security_outlined,
                selected: !_toDoor,
                onTap: () => setState(() => _toDoor = false),
              ),
            ),
          ]),
          const SizedBox(height: 28),

          SubmitButton(
            label: 'Register Parcel',
            loading: _saving,
            onTap: _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
            colorScheme: const ColorScheme.dark(primary: Color(0xFF7986CB))),
        child: child!,
      ),
    );
    if (p != null) setState(() => _date = p);
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await widget.svc.createParcel(
        residentUid:    widget.user.uid,
        residentName:   widget.user.displayName,
        flatNumber:     widget.user.flatNumber ?? '',
        type:           _type,
        expectedDate:   _date,
        deliveryToDoor: _toDoor,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'),
              backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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

// ── Small helpers ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12));
}

class _DateTile extends StatelessWidget {
  final DateTime date;
  const _DateTile({required this.date});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined,
              color: Colors.white38, size: 18),
          const SizedBox(width: 12),
          Text(DateFormat('dd MMM yyyy').format(date),
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
        ]),
      );
}

class _PrefTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _PrefTile(
      {required this.label, required this.icon,
       required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF3949AB) : const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? const Color(0xFF7986CB) : Colors.white12),
          ),
          child: Column(children: [
            Icon(icon, size: 22, color: selected ? Colors.white : Colors.white38),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: selected ? Colors.white : Colors.white38,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      );
}
