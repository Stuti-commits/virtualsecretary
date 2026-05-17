import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/meeting_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/secretary_service.dart';
import '../../../widgets/app_widgets.dart';

class MeetingsTab extends StatefulWidget {
  const MeetingsTab({super.key});

  @override
  State<MeetingsTab> createState() => _MeetingsTabState();
}

class _MeetingsTabState extends State<MeetingsTab> {
  late final Stream<List<MeetingModel>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = SecretaryService().streamMeetings();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentAppUser!;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFFB300),
        foregroundColor: Colors.black,
        icon:  const Icon(Icons.add),
        label: Text('Schedule Meeting',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _CreateMeetingSheet(user: user),
        ),
      ),
      body: StreamBuilder<List<MeetingModel>>(
        stream: _stream,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFB300)));
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.event_outlined,
              message: 'No meetings scheduled.\nTap + to create one.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _MeetingCard(
              meeting: list[i],
              onDelete: () => _confirmDelete(ctx, list[i].id),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext ctx, String id) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('Delete Meeting?',
            style: GoogleFonts.poppins(color: Colors.white)),
        content: Text('This cannot be undone.',
            style: GoogleFonts.poppins(color: Colors.white54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: GoogleFonts.poppins(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) await SecretaryService().deleteMeeting(id);
  }
}

// ── Meeting Card ──────────────────────────────────────────────────────────────

class _MeetingCard extends StatelessWidget {
  final MeetingModel meeting;
  final VoidCallback onDelete;
  const _MeetingCard({required this.meeting, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isPast = meeting.meetingDate.isBefore(DateTime.now());
    final color  = isPast ? Colors.white38 : const Color(0xFFFFB300);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header row ─────────────────────────────────────────
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isPast ? 'Completed' : 'Upcoming',
              style: GoogleFonts.poppins(
                  color: color, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
          if (meeting.notificationSent) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.notifications_active_outlined,
                    size: 11, color: Colors.green),
                const SizedBox(width: 4),
                Text('Notified',
                    style: GoogleFonts.poppins(
                        color: Colors.green,
                        fontSize: 10, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
          const Spacer(),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.white24, size: 18),
            onPressed: onDelete,
          ),
        ]),

        const SizedBox(height: 10),

        // ── Title ──────────────────────────────────────────────
        Text(meeting.title,
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700,
                fontSize: 16)),
        const SizedBox(height: 10),

        // ── Date / venue ───────────────────────────────────────
        InfoRow(
          icon: Icons.calendar_month_outlined,
          text: DateFormat('EEE, dd MMM yyyy  ·  h:mm a')
              .format(meeting.meetingDate),
        ),
        const SizedBox(height: 4),
        InfoRow(icon: Icons.location_on_outlined, text: meeting.venue),

        // ── Agenda ─────────────────────────────────────────────
        if (meeting.agenda.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Agenda',
              style: GoogleFonts.poppins(
                  color: Colors.white54, fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ...meeting.agenda.asMap().entries.map(
                (e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${e.key + 1}. ',
                      style: GoogleFonts.poppins(
                          color: const Color(0xFFFFB300), fontSize: 12)),
                  Expanded(
                    child: Text(e.value,
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 10),
        Text('By ${meeting.createdByName}',
            style: GoogleFonts.poppins(color: Colors.white24, fontSize: 11)),
      ]),
    );
  }
}

// ── Create Meeting Sheet ──────────────────────────────────────────────────────

class _CreateMeetingSheet extends StatefulWidget {
  final AppUser user;
  const _CreateMeetingSheet({required this.user});

  @override
  State<_CreateMeetingSheet> createState() => _CreateMeetingSheetState();
}

class _CreateMeetingSheetState extends State<_CreateMeetingSheet> {
  final _formKey     = GlobalKey<FormState>();
  final _titleCtrl   = TextEditingController();
  final _venueCtrl   = TextEditingController();
  final _svc         = SecretaryService();

  // Agenda: dynamic list of controllers
  final List<TextEditingController> _agendaCtrl = [TextEditingController()];

  DateTime _meetingDate = DateTime.now().add(const Duration(days: 3));
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _venueCtrl.dispose();
    for (final c in _agendaCtrl) c.dispose();
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
            const SheetHeader(title: 'Schedule Community Meeting'),

            // Title
            AppField(
              controller: _titleCtrl,
              label: 'Meeting Title',
              icon: Icons.title_rounded,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Title is required'
                  : null,
            ),
            const SizedBox(height: 14),

            // Venue
            AppField(
              controller: _venueCtrl,
              label: 'Venue (e.g. Clubhouse)',
              icon: Icons.location_on_outlined,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Venue is required'
                  : null,
            ),
            const SizedBox(height: 20),

            // Date & time picker
            _SectionLabel('Date & Time'),
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
                  const Icon(Icons.event_rounded,
                      color: Colors.white38, size: 18),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('dd MMM yyyy  ·  h:mm a').format(_meetingDate),
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 14),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 20),

            // Agenda items
            Row(children: [
              _SectionLabel('Agenda Items'),
              const Spacer(),
              GestureDetector(
                onTap: _addAgendaItem,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3949AB).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.add, size: 14, color: Color(0xFF7986CB)),
                    const SizedBox(width: 4),
                    Text('Add Item',
                        style: GoogleFonts.poppins(
                            color: const Color(0xFF7986CB),
                            fontSize: 11, fontWeight: FontWeight.w500)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 10),

            ..._agendaCtrl.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3949AB).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${e.key + 1}',
                        style: GoogleFonts.poppins(
                            color: const Color(0xFF7986CB),
                            fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppField(
                    controller: e.value,
                    label: 'Agenda point ${e.key + 1}',
                    icon: Icons.circle_outlined,
                  ),
                ),
                if (_agendaCtrl.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded,
                        color: Colors.white24, size: 20),
                    onPressed: () => _removeAgendaItem(e.key),
                  ),
              ]),
            )),

            const SizedBox(height: 8),

            // FCM note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3949AB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF3949AB).withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.notifications_outlined,
                    color: Color(0xFF7986CB), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All residents will be notified via push notification.',
                    style: GoogleFonts.poppins(
                        color: const Color(0xFF7986CB), fontSize: 11),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            SubmitButton(
              label: 'Create Meeting & Notify',
              loading: _saving,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }

  void _addAgendaItem() =>
      setState(() => _agendaCtrl.add(TextEditingController()));

  void _removeAgendaItem(int index) {
    _agendaCtrl[index].dispose();
    setState(() => _agendaCtrl.removeAt(index));
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _meetingDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
            colorScheme:
                const ColorScheme.dark(primary: Color(0xFFFFB300))),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_meetingDate),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
            colorScheme:
                const ColorScheme.dark(primary: Color(0xFFFFB300))),
        child: child!,
      ),
    );
    if (time == null) return;
    setState(() => _meetingDate = DateTime(
        date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _svc.createMeeting(
        title:         _titleCtrl.text.trim(),
        agenda:        _agendaCtrl.map((c) => c.text.trim()).toList(),
        meetingDate:   _meetingDate,
        venue:         _venueCtrl.text.trim(),
        createdByUid:  widget.user.uid,
        createdByName: widget.user.displayName,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Meeting created! Residents will be notified.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12));
}
