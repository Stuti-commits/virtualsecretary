import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum ParcelType { amazon, blinkit, swiggy, other }

extension ParcelTypeX on ParcelType {
  String get value => name; // 'amazon' | 'blinkit' | 'swiggy' | 'other'

  String get label {
    switch (this) {
      case ParcelType.amazon:  return 'Amazon';
      case ParcelType.blinkit: return 'Blinkit';
      case ParcelType.swiggy:  return 'Swiggy';
      case ParcelType.other:   return 'Other';
    }
  }

  static ParcelType fromString(String s) =>
      ParcelType.values.firstWhere((e) => e.name == s, orElse: () => ParcelType.other);
}

enum ParcelStatus { expected, arrived, collected }

extension ParcelStatusX on ParcelStatus {
  String get value => name;
  static ParcelStatus fromString(String s) =>
      ParcelStatus.values.firstWhere((e) => e.name == s, orElse: () => ParcelStatus.expected);
}

// ─── Model ────────────────────────────────────────────────────────────────────

class ParcelModel {
  final String id;
  final String residentUid;
  final String residentName;
  final String flatNumber;
  final ParcelType type;
  final DateTime expectedDate;
  final bool deliveryToDoor;
  final ParcelStatus status;
  final DateTime createdAt;
  final DateTime? arrivedAt;
  final DateTime? collectedAt;
  final String? arrivedByUid;

  const ParcelModel({
    required this.id,
    required this.residentUid,
    required this.residentName,
    required this.flatNumber,
    required this.type,
    required this.expectedDate,
    required this.deliveryToDoor,
    required this.status,
    required this.createdAt,
    this.arrivedAt,
    this.collectedAt,
    this.arrivedByUid,
  });

  factory ParcelModel.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return ParcelModel(
      id:              doc.id,
      residentUid:     m['residentUid']  ?? '',
      residentName:    m['residentName'] ?? '',
      flatNumber:      m['flatNumber']   ?? '',
      type:            ParcelTypeX.fromString(m['type'] ?? ''),
      expectedDate:    (m['expectedDate'] as Timestamp).toDate(),
      deliveryToDoor:  m['deliveryToDoor'] ?? false,
      status:          ParcelStatusX.fromString(m['status'] ?? ''),
      createdAt:       (m['createdAt'] as Timestamp).toDate(),
      arrivedAt:       m['arrivedAt']   != null ? (m['arrivedAt']   as Timestamp).toDate() : null,
      collectedAt:     m['collectedAt'] != null ? (m['collectedAt'] as Timestamp).toDate() : null,
      arrivedByUid:    m['arrivedByUid'],
    );
  }

  Map<String, dynamic> toMap() => {
    'residentUid':    residentUid,
    'residentName':   residentName,
    'flatNumber':     flatNumber,
    'type':           type.value,
    'expectedDate':   Timestamp.fromDate(expectedDate),
    'deliveryToDoor': deliveryToDoor,
    'status':         status.value,
    'createdAt':      Timestamp.fromDate(createdAt),
    'arrivedAt':      arrivedAt   != null ? Timestamp.fromDate(arrivedAt!)   : null,
    'collectedAt':    collectedAt != null ? Timestamp.fromDate(collectedAt!) : null,
    'arrivedByUid':   arrivedByUid,
  };
}
