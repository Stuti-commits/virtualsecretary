import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Fee Status ───────────────────────────────────────────────────────────────

enum FeeStatus { pending, paid }

extension FeeStatusX on FeeStatus {
  String get value => name; // 'pending' | 'paid'

  static FeeStatus fromString(String s) =>
      s == 'paid' ? FeeStatus.paid : FeeStatus.pending;
}

// ─── Fee Period ───────────────────────────────────────────────────────────────
// Represents the collection record for one flat for one month.
// Document ID pattern: "{YYYY-MM}_{flatNumber}"  e.g. "2025-06_A-101"

class FeeRecord {
  final String id;           // Firestore doc ID
  final String flatNumber;
  final String residentUid;
  final String residentName;
  final String period;       // "YYYY-MM"  e.g. "2025-06"
  final int    amount;       // in INR
  final FeeStatus status;
  final DateTime? paidAt;
  final String? markedByUid; // secretary who marked paid
  final DateTime createdAt;
  final DateTime updatedAt;

  const FeeRecord({
    required this.id,
    required this.flatNumber,
    required this.residentUid,
    required this.residentName,
    required this.period,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.paidAt,
    this.markedByUid,
  });

  factory FeeRecord.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return FeeRecord(
      id:           doc.id,
      flatNumber:   m['flatNumber']   ?? '',
      residentUid:  m['residentUid']  ?? '',
      residentName: m['residentName'] ?? '',
      period:       m['period']       ?? '',
      amount:       m['amount']       ?? 0,
      status:       FeeStatusX.fromString(m['status'] ?? ''),
      paidAt:       m['paidAt'] != null
                      ? (m['paidAt'] as Timestamp).toDate()
                      : null,
      markedByUid:  m['markedByUid'],
      createdAt:    (m['createdAt'] as Timestamp).toDate(),
      updatedAt:    (m['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'flatNumber':   flatNumber,
    'residentUid':  residentUid,
    'residentName': residentName,
    'period':       period,
    'amount':       amount,
    'status':       status.value,
    'paidAt':       paidAt != null ? Timestamp.fromDate(paidAt!) : null,
    'markedByUid':  markedByUid,
    'createdAt':    Timestamp.fromDate(createdAt),
    'updatedAt':    Timestamp.fromDate(updatedAt),
  };
}
