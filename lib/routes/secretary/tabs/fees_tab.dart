import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/fee_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/secretary_service.dart';
import '../../../widgets/app_widgets.dart';

class FeesTab extends StatefulWidget {
  const FeesTab({super.key});

  @override
  State<FeesTab> createState() => _FeesTabState();
}

class _FeesTabState extends State<FeesTab> {
  // Current period defaults to this month
  late DateTime _selectedMonth;
  late String   _period;
  late Stream<List<FeeRecord>> _stream;
  final _svc = SecretaryService();

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _period        = SecretaryService.periodKey(_selectedMonth);
    _stream        = _svc.streamFeesForPeriod(_period);
  }

  void _switchMonth(DateTime month) {
    setState(() {
      _selectedMonth = month;
      _period        = SecretaryService.periodKey(month);
      _stream        = _svc.streamFeesForPeriod(_period);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentAppUser!;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Column(
        children: [
          // ── Month selector + actions ───────────────────────────
          _MonthBar(
            selected:    _selectedMonth,
            period:      _period,
            secretaryUid: user.uid,
            svc:         _svc,
            onPrev: () => _switchMonth(
                DateTime(_selectedMonth.year, _selectedMonth.month - 1)),
            onNext: () => _switchMonth(
                DateTime(_selectedMonth.year, _selectedMonth.month + 1)),
          ),

          // ── Fee list ───────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<FeeRecord>>(
              stream: _stream,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFFFB300)));
                }
                final records = snap.data ?? [];

                if (records.isEmpty) {
                  return _EmptyFees(
                    period:      _period,
                    secretaryUid: user.uid,
                    svc:         _svc,
                  );
                }

                // ── Summary bar ──────────────────────────────
                final paid    = records.where((r) => r.status == FeeStatus.paid).length;
                final total   = records.length;
                final paidAmt = records
                    .where((r) => r.status == FeeStatus.paid)
                    .fold(0, (sum, r) => sum + r.amount);
                final totalAmt = records.fold(0, (sum, r) => sum + r.amount);

                return Column(children: [
                  _SummaryBar(
                      paid: paid, total: total,
                      paidAmt: paidAmt, totalAmt: totalAmt),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: records.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _FeeCard(
                        record:      records[i],
                        secretaryUid: user.uid,
                        svc:         _svc,
                      ),
                    ),
                  ),
                ]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Month bar ─────────────────────────────────────────────────────────────────

class _MonthBar extends StatelessWidget {
  final DateTime selected;
  final String period;
  final String secretaryUid;
  final SecretaryService svc;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthBar({
    required this.selected,
    required this.period,
    required this.secretaryUid,
    required this.svc,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF12122A),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(children: [
        // Month navigation
        Row(children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white54),
            onPressed: onPrev,
          ),
          Expanded(
            child: Text(
              DateFormat('MMMM yyyy').format(selected),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            onPressed: onNext,
          ),
        ]),

        const SizedBox(height: 8),

        // Action row
        Row(children: [
          Expanded(
            child: _BarBtn(
              label: 'Seed Records',
              icon: Icons.refresh_rounded,
              color: const Color(0xFF7986CB),
              onTap: () => _seed(context),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _BarBtn(
              label: 'Send Reminders',
              icon: Icons.notifications_outlined,
              color: const Color(0xFFFFB300),
              onTap: () => _remind(context),
            ),
          ),
        ]),
      ]),
    );
  }

  Future<void> _seed(BuildContext ctx) async {
    try {
      await svc.seedFeeRecordsForPeriod(period: period);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Fee records seeded for $period',
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Error: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _remind(BuildContext ctx) async {
    try {
      await svc.sendFeeReminders(period);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Reminders queued for pending flats.',
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Error: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}

class _BarBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _BarBtn(
      {required this.label, required this.icon,
       required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    color: color, fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

// ── Summary bar ───────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final int paid;
  final int total;
  final int paidAmt;
  final int totalAmt;
  const _SummaryBar(
      {required this.paid, required this.total,
       required this.paidAmt, required this.totalAmt});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : paid / total;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(children: [
        Row(children: [
          _Stat(
            label: 'Collected',
            value: '₹${_fmt(paidAmt)}',
            color: Colors.green,
          ),
          const Spacer(),
          _Stat(
            label: 'Pending',
            value: '₹${_fmt(totalAmt - paidAmt)}',
            color: Colors.redAccent,
            align: TextAlign.right,
          ),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: Colors.white10,
            valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$paid of $total flats paid',
          style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
        ),
      ]),
    );
  }

  String _fmt(int n) => NumberFormat('#,##,###').format(n);
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final TextAlign align;
  const _Stat({
    required this.label, required this.value, required this.color,
    this.align = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: align == TextAlign.right
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: GoogleFonts.poppins(
                  color: color, fontSize: 18,
                  fontWeight: FontWeight.w700)),
        ],
      );
}

// ── Fee Card ──────────────────────────────────────────────────────────────────

class _FeeCard extends StatelessWidget {
  final FeeRecord record;
  final String secretaryUid;
  final SecretaryService svc;
  const _FeeCard(
      {required this.record, required this.secretaryUid, required this.svc});

  @override
  Widget build(BuildContext context) {
    final isPaid = record.status == FeeStatus.paid;
    final color  = isPaid ? Colors.green : Colors.redAccent;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        // Flat avatar
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              record.flatNumber.length > 4
                  ? record.flatNumber.substring(0, 4)
                  : record.flatNumber,
              style: GoogleFonts.poppins(
                  color: color, fontWeight: FontWeight.w700,
                  fontSize: 11),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Name + date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(record.residentName,
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w600,
                      fontSize: 14)),
              const SizedBox(height: 2),
              Text(
                isPaid && record.paidAt != null
                    ? 'Paid on ${DateFormat('dd MMM').format(record.paidAt!)}'
                    : 'Due: ₹${record.amount}',
                style: GoogleFonts.poppins(
                    color: isPaid ? Colors.green.shade300 : Colors.redAccent,
                    fontSize: 11),
              ),
            ],
          ),
        ),

        // Toggle button
        GestureDetector(
          onTap: () => isPaid
              ? svc.markFeePending(record.id)
              : svc.markFeePaid(record.id, secretaryUid),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Text(
              isPaid ? 'Undo' : 'Mark Paid',
              style: GoogleFonts.poppins(
                  color: color, fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyFees extends StatelessWidget {
  final String period;
  final String secretaryUid;
  final SecretaryService svc;
  const _EmptyFees(
      {required this.period, required this.secretaryUid, required this.svc});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 56, color: Colors.white12),
          const SizedBox(height: 16),
          Text('No fee records for this month.',
              style:
                  GoogleFonts.poppins(color: Colors.white38, fontSize: 14)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              await svc.seedFeeRecordsForPeriod(period: period);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFFFB300).withOpacity(0.5)),
              ),
              child: Text('Seed Records for $period',
                  style: GoogleFonts.poppins(
                      color: const Color(0xFFFFB300),
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
