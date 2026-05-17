import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/meeting_model.dart';
import '../models/fee_model.dart';

const int kDefaultFeeAmount = 2000; // INR

class SecretaryService {
  static final SecretaryService _i = SecretaryService._();
  factory SecretaryService() => _i;
  SecretaryService._();

  final _db   = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ═══════════════════════════════════════════════════════════════════════════
  // MEETINGS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<String> createMeeting({
    required String title,
    required List<String> agenda,
    required DateTime meetingDate,
    required String venue,
    required String createdByUid,
    required String createdByName,
  }) async {
    final id  = _uuid.v4();
    final now = DateTime.now();
    await _db.collection('meeting_notices').doc(id).set(MeetingModel(
      id:               id,
      title:            title,
      agenda:           agenda.where((a) => a.trim().isNotEmpty).toList(),
      meetingDate:      meetingDate,
      venue:            venue,
      createdByUid:     createdByUid,
      createdByName:    createdByName,
      createdAt:        now,
      notificationSent: false,
    ).toMap());
    await _notifyResidents(
      title: title,
      venue: venue,
      meetingDate: meetingDate,
    );
    return id;
  }
  Future<void> _notifyResidents({
    required String title,
    required String venue,
    required DateTime meetingDate,
  }) async {

    final users = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'resident')
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (final user in users.docs) {

      final notificationRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .collection('notifications')
          .doc();

      batch.set(notificationRef, {
        'title': 'New Community Meeting',
        'body':
        '$title at $venue on ${DateFormat('dd MMM • hh:mm a').format(meetingDate)}',
        'createdAt': Timestamp.now(),
        'read': false,
        'type': 'meeting',
      });
    }

    await batch.commit();
  }
  Stream<List<MeetingModel>> streamMeetings() => _db
      .collection('meeting_notices')
      .orderBy('meetingDate', descending: true)
      .snapshots()
      .map((s) => s.docs.map(MeetingModel.fromDoc).toList());

  Stream<List<MeetingModel>> streamUpcomingMeetings() => _db
      .collection('meeting_notices')
      .where('meetingDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
      .orderBy('meetingDate')
      .snapshots()
      .map((s) => s.docs.map(MeetingModel.fromDoc).toList());

  Future<void> deleteMeeting(String id) =>
      _db.collection('meeting_notices').doc(id).delete();

  // ═══════════════════════════════════════════════════════════════════════════
  // MAINTENANCE FEES
  // ═══════════════════════════════════════════════════════════════════════════

  static String periodKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}';

  /// Seeds pending fee records for every resident for a given month.
  /// Uses merge so existing paid records are never overwritten.
  Future<void> seedFeeRecordsForPeriod({
    required String period,
    int amount = kDefaultFeeAmount,
  }) async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: 'resident')
        .get();

    final batch = _db.batch();
    final now   = DateTime.now();

    for (final doc in snap.docs) {
      final data  = doc.data();
      final flat  = (data['flatNumber'] as String?)?.isNotEmpty == true
          ? data['flatNumber'] as String
          : doc.id.substring(0, 6); // fallback if flatNumber not set
      final docId = '${period}_$flat';
      final ref   = _db.collection('maintenance_fees').doc(docId);

      batch.set(
        ref,
        FeeRecord(
          id:           docId,
          flatNumber:   flat,
          residentUid:  doc.id,
          residentName: data['displayName'] as String? ?? '',
          period:       period,
          amount:       amount,
          status:       FeeStatus.pending,
          createdAt:    now,
          updatedAt:    now,
        ).toMap(),
        SetOptions(merge: true), // never overwrite paid status
      );
    }
    await batch.commit();
  }

  Future<void> markFeePaid(String docId, String secretaryUid) =>
      _db.collection('maintenance_fees').doc(docId).update({
        'status':      FeeStatus.paid.value,
        'paidAt':      FieldValue.serverTimestamp(),
        'markedByUid': secretaryUid,
        'updatedAt':   FieldValue.serverTimestamp(),
      });

  Future<void> markFeePending(String docId) =>
      _db.collection('maintenance_fees').doc(docId).update({
        'status':      FeeStatus.pending.value,
        'paidAt':      null,
        'markedByUid': null,
        'updatedAt':   FieldValue.serverTimestamp(),
      });

  Stream<List<FeeRecord>> streamFeesForPeriod(String period) => _db
      .collection('maintenance_fees')
      .where('period', isEqualTo: period)
      .orderBy('flatNumber')
      .snapshots()
      .map((s) => s.docs.map(FeeRecord.fromDoc).toList());

  Stream<List<FeeRecord>> streamMyFees(String residentUid) => _db
      .collection('maintenance_fees')
      .where('residentUid', isEqualTo: residentUid)
      .orderBy('period', descending: true)
      .snapshots()
      .map((s) => s.docs.map(FeeRecord.fromDoc).toList());

  /// Writes a log entry; your Cloud Function picks this up and sends FCM
  /// to all pending residents for the period.
  Future<void> sendFeeReminders(String period) async {
    debugPrint('[SecretaryService] sendFeeReminders → $period');
    await _db.collection('fee_reminder_logs').add({
      'period':    period,
      'sentAt':    FieldValue.serverTimestamp(),
      'processed': false,
    });
  }
}
