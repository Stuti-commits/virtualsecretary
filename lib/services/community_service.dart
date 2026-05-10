import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/parcel_model.dart';
import '../models/visitor_model.dart';
import '../models/maintenance_issue_model.dart';

class CommunityService {
  static final CommunityService _i = CommunityService._();
  factory CommunityService() => _i;
  CommunityService._();

  final _db      = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _uuid    = const Uuid();

  // ═══════════════════════════════════════════════════════════════════
  // PARCELS
  // ═══════════════════════════════════════════════════════════════════

  Future<void> createParcel({
    required String residentUid,
    required String residentName,
    required String flatNumber,
    required ParcelType type,
    required DateTime expectedDate,
    required bool deliveryToDoor,
  }) async {
    final id  = _uuid.v4();
    final now = DateTime.now();
    await _db.collection('parcels').doc(id).set(ParcelModel(
      id:             id,
      residentUid:    residentUid,
      residentName:   residentName,
      flatNumber:     flatNumber,
      type:           type,
      expectedDate:   expectedDate,
      deliveryToDoor: deliveryToDoor,
      status:         ParcelStatus.expected,
      createdAt:      now,
    ).toMap());
  }

  Future<void> markParcelArrived(String parcelId, String guardUid) =>
      _db.collection('parcels').doc(parcelId).update({
        'status':       ParcelStatus.arrived.value,
        'arrivedAt':    FieldValue.serverTimestamp(),
        'arrivedByUid': guardUid,
      });

  Future<void> markParcelCollected(String parcelId) =>
      _db.collection('parcels').doc(parcelId).update({
        'status':      ParcelStatus.collected.value,
        'collectedAt': FieldValue.serverTimestamp(),
      });

  /// Security: all expected + arrived parcels, real-time.
  Stream<List<ParcelModel>> streamActiveParcels() => _db
      .collection('parcels')
      .where('status', whereIn: ['expected', 'arrived'])
      .orderBy('expectedDate')
      .snapshots()
      .map((s) => s.docs.map(ParcelModel.fromDoc).toList());

  /// Resident: their own parcels, real-time.
  Stream<List<ParcelModel>> streamMyParcels(String uid) => _db
      .collection('parcels')
      .where('residentUid', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ParcelModel.fromDoc).toList());

  // ═══════════════════════════════════════════════════════════════════
  // VISITORS
  // ═══════════════════════════════════════════════════════════════════

  Future<void> createVisitor({
    required String name,
    required String phone,
    required String purposeNote,
    required String flatNumber,
    required String residentUid,
    required String residentName,
    required DateTime expectedTime,
  }) async {
    final id = _uuid.v4();
    await _db.collection('visitors').doc(id).set(VisitorModel(
      id:           id,
      name:         name,
      phone:        phone,
      purposeNote:  purposeNote,
      flatNumber:   flatNumber,
      residentUid:  residentUid,
      residentName: residentName,
      expectedTime: expectedTime,
      status:       VisitorStatus.approved,
      createdAt:    DateTime.now(),
    ).toMap());
  }

  Future<void> markCheckedIn(String visitorId, String guardUid) =>
      _db.collection('visitors').doc(visitorId).update({
        'status':          VisitorStatus.checkedIn.value,
        'checkedInAt':     FieldValue.serverTimestamp(),
        'checkedInByUid':  guardUid,
      });

  Future<void> markCheckedOut(String visitorId) =>
      _db.collection('visitors').doc(visitorId).update({
        'status':       VisitorStatus.checkedOut.value,
        'checkedOutAt': FieldValue.serverTimestamp(),
      });

  /// Security: approved + checked-in visitors expected today.
  Stream<List<VisitorModel>> streamTodayVisitors() {
    final midnight = DateTime.now().copyWith(
        hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    return _db
        .collection('visitors')
        .where('expectedTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(midnight))
        .where('status', whereIn: ['approved', 'checked_in'])
        .orderBy('expectedTime')
        .snapshots()
        .map((s) => s.docs.map(VisitorModel.fromDoc).toList());
  }

  /// Resident: their own visitor log, real-time.
  Stream<List<VisitorModel>> streamMyVisitors(String uid) => _db
      .collection('visitors')
      .where('residentUid', isEqualTo: uid)
      .orderBy('expectedTime', descending: true)
      .snapshots()
      .map((s) => s.docs.map(VisitorModel.fromDoc).toList());

  // ═══════════════════════════════════════════════════════════════════
  // MAINTENANCE ISSUES
  // ═══════════════════════════════════════════════════════════════════

  Future<List<String>> _uploadPhotos(List<File> files, String issueId) async {
    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final ref = _storage.ref('maintenance/$issueId/photo_$i.jpg');
      await ref.putFile(files[i]);
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  Future<void> createIssue({
    required String title,
    required String description,
    required IssueCategory category,
    required String reportedByUid,
    required String reportedByName,
    required String flatNumber,
    List<File> photos = const [],
  }) async {
    final id  = _uuid.v4();
    final now = DateTime.now();
    final urls = photos.isEmpty ? <String>[] : await _uploadPhotos(photos, id);
    await _db.collection('maintenance_issues').doc(id).set(MaintenanceIssue(
      id:             id,
      title:          title,
      description:    description,
      category:       category,
      status:         IssueStatus.open,
      photoUrls:      urls,
      reportedByUid:  reportedByUid,
      reportedByName: reportedByName,
      flatNumber:     flatNumber,
      createdAt:      now,
      updatedAt:      now,
    ).toMap());
  }

  Future<void> updateIssueStatus(String issueId, IssueStatus newStatus) =>
      _db.collection('maintenance_issues').doc(issueId).update({
        'status':     newStatus.value,
        'updatedAt':  FieldValue.serverTimestamp(),
        if (newStatus == IssueStatus.resolved) 'resolvedAt': FieldValue.serverTimestamp(),
      });

  /// Secretary: all issues newest-first.
  Stream<List<MaintenanceIssue>> streamAllIssues() => _db
      .collection('maintenance_issues')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(MaintenanceIssue.fromDoc).toList());

  /// Resident: their own issues.
  Stream<List<MaintenanceIssue>> streamMyIssues(String uid) => _db
      .collection('maintenance_issues')
      .where('reportedByUid', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(MaintenanceIssue.fromDoc).toList());
}
