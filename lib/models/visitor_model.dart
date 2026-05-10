import 'package:cloud_firestore/cloud_firestore.dart';

enum VisitorStatus { approved, checkedIn, checkedOut }

extension VisitorStatusX on VisitorStatus {
  String get value {
    switch (this) {
      case VisitorStatus.approved:   return 'approved';
      case VisitorStatus.checkedIn:  return 'checked_in';
      case VisitorStatus.checkedOut: return 'checked_out';
    }
  }

  String get label {
    switch (this) {
      case VisitorStatus.approved:   return 'Approved';
      case VisitorStatus.checkedIn:  return 'Inside';
      case VisitorStatus.checkedOut: return 'Left';
    }
  }

  static VisitorStatus fromString(String s) {
    switch (s) {
      case 'checked_in':  return VisitorStatus.checkedIn;
      case 'checked_out': return VisitorStatus.checkedOut;
      default:            return VisitorStatus.approved;
    }
  }
}

class VisitorModel {
  final String id;
  final String name;
  final String phone;
  final String purposeNote;
  final String flatNumber;
  final String residentUid;
  final String residentName;
  final DateTime expectedTime;
  final VisitorStatus status;
  final DateTime createdAt;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;
  final String? checkedInByUid;

  const VisitorModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.purposeNote,
    required this.flatNumber,
    required this.residentUid,
    required this.residentName,
    required this.expectedTime,
    required this.status,
    required this.createdAt,
    this.checkedInAt,
    this.checkedOutAt,
    this.checkedInByUid,
  });

  factory VisitorModel.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return VisitorModel(
      id:              doc.id,
      name:            m['name']         ?? '',
      phone:           m['phone']        ?? '',
      purposeNote:     m['purposeNote']  ?? '',
      flatNumber:      m['flatNumber']   ?? '',
      residentUid:     m['residentUid']  ?? '',
      residentName:    m['residentName'] ?? '',
      expectedTime:    (m['expectedTime'] as Timestamp).toDate(),
      status:          VisitorStatusX.fromString(m['status'] ?? ''),
      createdAt:       (m['createdAt'] as Timestamp).toDate(),
      checkedInAt:     m['checkedInAt']  != null ? (m['checkedInAt']  as Timestamp).toDate() : null,
      checkedOutAt:    m['checkedOutAt'] != null ? (m['checkedOutAt'] as Timestamp).toDate() : null,
      checkedInByUid:  m['checkedInByUid'],
    );
  }

  Map<String, dynamic> toMap() => {
    'name':            name,
    'phone':           phone,
    'purposeNote':     purposeNote,
    'flatNumber':      flatNumber,
    'residentUid':     residentUid,
    'residentName':    residentName,
    'expectedTime':    Timestamp.fromDate(expectedTime),
    'status':          status.value,
    'createdAt':       Timestamp.fromDate(createdAt),
    'checkedInAt':     checkedInAt  != null ? Timestamp.fromDate(checkedInAt!)  : null,
    'checkedOutAt':    checkedOutAt != null ? Timestamp.fromDate(checkedOutAt!) : null,
    'checkedInByUid':  checkedInByUid,
  };
}
