import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/maintenance_issue_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/community_service.dart';
import '../../../widgets/app_widgets.dart';

class ResidentIssuesTab extends StatefulWidget {
  const ResidentIssuesTab({super.key});

  @override
  State<ResidentIssuesTab> createState() => _ResidentIssuesTabState();
}

class _ResidentIssuesTabState extends State<ResidentIssuesTab> {
  late final Stream<List<MaintenanceIssue>> _stream;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthService>().currentAppUser!.uid;
    _stream = CommunityService().streamMyIssues(uid);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentAppUser!;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFFB300),
        foregroundColor: Colors.black,
        icon:  const Icon(Icons.add_circle_outline_rounded),
        label: Text('Report Issue',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _FileIssueSheet(user: user, svc: CommunityService()),
        ),
      ),
      body: StreamBuilder<List<MaintenanceIssue>>(
        stream: _stream,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF7986CB)));
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.build_outlined,
              message: 'No issues reported yet.\nTap + to report a problem.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _IssueCard(issue: list[i]),
          );
        },
      ),
    );
  }
}

// ── Issue card ────────────────────────────────────────────────────────────────

class _IssueCard extends StatefulWidget {
  final MaintenanceIssue issue;
  const _IssueCard({required this.issue});

  @override
  State<_IssueCard> createState() => _IssueCardState();
}

class _IssueCardState extends State<_IssueCard> {
  @override
  Widget build(BuildContext context) {
    final issue = widget.issue;
    final sc = _statusColor(issue.status);
    final cc = _catColor(issue.category);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sc.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cc.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(issue.category.label,
                style: GoogleFonts.poppins(
                    color: cc, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          const Spacer(),
          StatusBadge(label: issue.status.label, color: sc),
        ]),
        const SizedBox(height: 10),
        Text(issue.title,
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 4),
        Text(issue.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        Text(DateFormat('dd MMM yyyy').format(issue.createdAt),
            style: GoogleFonts.poppins(color: Colors.white24, fontSize: 11)),
      ]),
    );
  }

  Color _statusColor(IssueStatus s) {
    switch (s) {
      case IssueStatus.open:       return Colors.redAccent;
      case IssueStatus.inProgress: return const Color(0xFFFFB300);
      case IssueStatus.resolved:   return Colors.green;
    }
  }

  Color _catColor(IssueCategory c) {
    switch (c) {
      case IssueCategory.plumbing:   return Colors.blueAccent;
      case IssueCategory.electrical: return Colors.orangeAccent;
      case IssueCategory.commonArea: return Colors.tealAccent;
      case IssueCategory.amenities:  return Colors.purpleAccent;
      case IssueCategory.Others:     return Colors.white;
    }
  }
}

// ── File issue sheet ──────────────────────────────────────────────────────────

class _FileIssueSheet extends StatefulWidget {
  final AppUser user;
  final CommunityService svc;
  const _FileIssueSheet({required this.user, required this.svc});

  @override
  State<_FileIssueSheet> createState() => _FileIssueSheetState();
}

class _FileIssueSheetState extends State<_FileIssueSheet> {
  final _formKey   = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  IssueCategory _category = IssueCategory.plumbing;
  final List<File> _photos = [];
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
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
            const SheetHeader(title: 'Report Maintenance Issue'),

            // Category chips
            Text('Category',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: IssueCategory.values.map((cat) {
                final sel = _category == cat;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? const Color(0xFF3949AB)
                          : const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel
                              ? const Color(0xFF7986CB)
                              : Colors.white12),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_catIcon(cat), size: 14,
                          color: sel ? Colors.white : Colors.white38),
                      const SizedBox(width: 6),
                      Text(cat.label,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: sel ? Colors.white : Colors.white54,
                              fontWeight: FontWeight.w500)),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            AppField(
              controller: _titleCtrl,
              label: 'Issue Title',
              icon: Icons.title_rounded,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Title is required'
                  : null,
            ),
            const SizedBox(height: 14),
            AppField(
              controller: _descCtrl,
              label: 'Description',
              icon: Icons.description_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // Photo upload row
            Text('Photos (max 3)',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 10),
            Row(children: [
              ..._photos.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(f,
                          width: 64, height: 64, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 2, right: 2,
                      child: GestureDetector(
                        onTap: () => setState(() => _photos.remove(f)),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              if (_photos.length < 3)
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Icon(Icons.add_photo_alternate_outlined,
                        color: Colors.white38, size: 28),
                  ),
                ),
            ]),
            const SizedBox(height: 28),

            SubmitButton(
              label: 'Submit Issue',
              loading: _saving,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final p = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (p != null) setState(() => _photos.add(File(p.path)));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.svc.createIssue(
        title:          _titleCtrl.text.trim(),
        description:    _descCtrl.text.trim(),
        category:       _category,
        reportedByUid:  widget.user.uid,
        reportedByName: widget.user.displayName,
        flatNumber:     widget.user.flatNumber ?? '',
        photos:         _photos,
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

  IconData _catIcon(IssueCategory c) {
    switch (c) {
      case IssueCategory.plumbing:   return Icons.water_drop_outlined;
      case IssueCategory.electrical: return Icons.bolt_outlined;
      case IssueCategory.commonArea: return Icons.park_outlined;
      case IssueCategory.amenities:  return Icons.pool_outlined;
      case IssueCategory.Others: return Icons.build_outlined;
    }
  }
}
