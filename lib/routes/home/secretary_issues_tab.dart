// This is the existing issues dashboard, extracted into its own tab widget
// so SecretaryHomeScreen can compose it alongside MeetingsTab and FeesTab.
// Copy the body of the old SecretaryHomeScreen here.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../models/maintenance_issue_model.dart';
import '../../../services/community_service.dart';
import '../../../widgets/app_widgets.dart';

class SecretaryIssuesTab extends StatefulWidget {
  const SecretaryIssuesTab({super.key});

  @override
  State<SecretaryIssuesTab> createState() => _SecretaryIssuesTabState();
}

class _SecretaryIssuesTabState extends State<SecretaryIssuesTab> {
  IssueStatus? _filter;
  late final Stream<List<MaintenanceIssue>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = CommunityService().streamAllIssues();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filter chips ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _Chip(label: 'All',
                    color: Colors.white54, selected: _filter == null,
                    onTap: () => setState(() => _filter = null)),
                const SizedBox(width: 8),
                _Chip(label: 'Open',
                    color: Colors.redAccent,
                    selected: _filter == IssueStatus.open,
                    onTap: () => setState(() => _filter = IssueStatus.open)),
                const SizedBox(width: 8),
                _Chip(label: 'In Progress',
                    color: const Color(0xFFFFB300),
                    selected: _filter == IssueStatus.inProgress,
                    onTap: () =>
                        setState(() => _filter = IssueStatus.inProgress)),
                const SizedBox(width: 8),
                _Chip(label: 'Resolved',
                    color: Colors.green,
                    selected: _filter == IssueStatus.resolved,
                    onTap: () =>
                        setState(() => _filter = IssueStatus.resolved)),
              ]),
            ),
          ),

          // ── List ────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<MaintenanceIssue>>(
              stream: _stream,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFFFB300)));
                }
                var list = snap.data ?? [];
                if (_filter != null) {
                  list =
                      list.where((i) => i.status == _filter).toList();
                }
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.build_outlined,
                    message: _filter == null
                        ? 'No maintenance issues filed yet.'
                        : 'No ${_filter!.label.toLowerCase()} issues.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) =>
                      _IssueCard(issue: list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Issue card ────────────────────────────────────────────────────────────────

class _IssueCard extends StatelessWidget {
  final MaintenanceIssue issue;
  const _IssueCard({required this.issue});

  @override
  Widget build(BuildContext context) {
    final sc = _statusColor(issue.status);
    final cc = _catColor(issue.category);
    final svc = CommunityService();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sc.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cc.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(issue.category.label,
                style: GoogleFonts.poppins(
                    color: cc, fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ),
          const Spacer(),
          Text(DateFormat('dd MMM').format(issue.createdAt),
              style:
                  GoogleFonts.poppins(color: Colors.white24, fontSize: 11)),
        ]),
        const SizedBox(height: 10),
        Text(issue.title,
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600,
                fontSize: 15)),
        const SizedBox(height: 4),
        Text(issue.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        InfoRow(
          icon: Icons.person_outline_rounded,
          text:
              '${issue.reportedByName}  ·  Flat ${issue.flatNumber}',
        ),
        if (issue.photoUrls.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: issue.photoUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(issue.photoUrls[i],
                    width: 60, height: 60, fit: BoxFit.cover),
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Row(children: [
          StatusBadge(label: issue.status.label, color: sc),
          const SizedBox(width: 10),
          if (issue.status == IssueStatus.open)
            _NextBtn(
              label: '→ In Progress',
              color: const Color(0xFFFFB300),
              onTap: () => svc.updateIssueStatus(
                  issue.id, IssueStatus.inProgress),
            ),
          if (issue.status == IssueStatus.inProgress)
            _NextBtn(
              label: '→ Resolved',
              color: Colors.green,
              onTap: () =>
                  svc.updateIssueStatus(issue.id, IssueStatus.resolved),
            ),
          if (issue.status == IssueStatus.resolved)
            Text('✓ Closed',
                style: GoogleFonts.poppins(
                    color: Colors.green, fontSize: 12)),
        ]),
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
      case IssueCategory.Others: return Colors.white;
    }
  }
}

class _NextBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _NextBtn(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Text(label,
              style: GoogleFonts.poppins(
                  color: color, fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(
      {required this.label, required this.color,
       required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(0.15)
                : const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? color : Colors.white12),
          ),
          child: Text(label,
              style: GoogleFonts.poppins(
                  color: selected ? color : Colors.white38,
                  fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      );
}
