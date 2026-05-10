import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/visitor_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/community_service.dart';
import '../../../widgets/app_widgets.dart';

class ResidentVisitorsTab extends StatelessWidget {
  const ResidentVisitorsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentAppUser!;
    final svc  = CommunityService();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFFB300),
        foregroundColor: Colors.black,
        icon:  const Icon(Icons.person_add_rounded),
        label: Text('Pre-Approve Guest',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _AddVisitorSheet(user: user, svc: svc),
        ),
      ),
      body: StreamBuilder<List<VisitorModel>>(
        stream: svc.streamMyVisitors(user.uid),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF7986CB)));
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline_rounded,
              message: 'No visitors yet.\nTap + to pre-approve a guest.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _VisitorCard(visitor: list[i]),
          );
        },
      ),
    );
  }
}

// ── Visitor card ──────────────────────────────────────────────────────────────

class _VisitorCard extends StatelessWidget {
  final VisitorModel visitor;
  const _VisitorCard({required this.visitor});

  @override
  Widget build(BuildContext context) {
    final color = _color(visitor.status);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(0.15),
          child: Text(
            visitor.name.isNotEmpty ? visitor.name[0].toUpperCase() : '?',
            style: GoogleFonts.poppins(
                color: color, fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(visitor.name,
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600,
                    fontSize: 15)),
            const SizedBox(height: 2),
            Text(
              '${visitor.phone}  ·  '
              '${DateFormat('dd MMM, h:mm a').format(visitor.expectedTime)}',
              style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
            ),
            if (visitor.purposeNote.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(visitor.purposeNote,
                    style:
                        GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
              ),
          ]),
        ),
        StatusBadge(label: visitor.status.label, color: color),
      ]),
    );
  }

  Color _color(VisitorStatus s) {
    switch (s) {
      case VisitorStatus.approved:   return const Color(0xFF7986CB);
      case VisitorStatus.checkedIn:  return const Color(0xFFFFB300);
      case VisitorStatus.checkedOut: return Colors.green;
    }
  }
}

// ── Add visitor sheet ─────────────────────────────────────────────────────────

class _AddVisitorSheet extends StatefulWidget {
  final AppUser user;
  final CommunityService svc;
  const _AddVisitorSheet({required this.user, required this.svc});

  @override
  State<_AddVisitorSheet> createState() => _AddVisitorSheetState();
}

class _AddVisitorSheetState extends State<_AddVisitorSheet> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _noteCtrl   = TextEditingController();
  DateTime _expectedTime = DateTime.now().add(const Duration(hours: 2));
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHeader(title: 'Pre-Approve Visitor'),

            AppField(
              controller: _nameCtrl,
              label: 'Guest Name',
              icon: Icons.person_outline_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),
            AppField(
              controller: _phoneCtrl,
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Phone is required' : null,
            ),
            const SizedBox(height: 14),
            AppField(
              controller: _noteCtrl,
              label: 'Purpose of visit (optional)',
              icon: Icons.notes_rounded,
            ),
            const SizedBox(height: 20),

            Text('Expected Arrival',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDateTime,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(children: [
                  const Icon(Icons.access_time_rounded,
                      color: Colors.white38, size: 18),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('dd MMM yyyy, h:mm a').format(_expectedTime),
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 28),

            SubmitButton(
              label: 'Approve Visit',
              loading: _saving,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expectedTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
            colorScheme: const ColorScheme.dark(primary: Color(0xFF7986CB))),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_expectedTime),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
            colorScheme: const ColorScheme.dark(primary: Color(0xFF7986CB))),
        child: child!,
      ),
    );
    if (time == null) return;
    setState(() => _expectedTime = DateTime(
        date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.svc.createVisitor(
        name:         _nameCtrl.text.trim(),
        phone:        _phoneCtrl.text.trim(),
        purposeNote:  _noteCtrl.text.trim(),
        flatNumber:   widget.user.flatNumber ?? '',
        residentUid:  widget.user.uid,
        residentName: widget.user.displayName,
        expectedTime: _expectedTime,
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
}
