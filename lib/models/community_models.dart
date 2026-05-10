import 'package:cloud_firestore/cloud_firestore.dart';

enum ParcelType { amazon, blinkit, swiggy, other }

enum ParcelStatus { expected, arrived, collected }

enum MaintenanceCategory { plumbing, electrical, commonArea, amenities }

enum MaintenanceStatus { open, inProgress, resolved }

enum VisitorStatus { approved, entered, exited }

String parcelTypeLabel(ParcelType value) {
  switch (value) {
    case ParcelType.amazon:
      return 'Amazon';
    case ParcelType.blinkit:
      return 'Blinkit';
    case ParcelType.swiggy:
      return 'Swiggy';
    case ParcelType.other:
      return 'Other';
  }
}

String parcelStatusLabel(ParcelStatus value) {
  switch (value) {
    case ParcelStatus.expected:
      return 'Expected';
    case ParcelStatus.arrived:
      return 'Arrived';
    case ParcelStatus.collected:
      return 'Collected';
  }
}

String maintenanceCategoryLabel(MaintenanceCategory value) {
  switch (value) {
    case MaintenanceCategory.plumbing:
      return 'Plumbing';
    case MaintenanceCategory.electrical:
      return 'Electrical';
    case MaintenanceCategory.commonArea:
      return 'Common Area';
    case MaintenanceCategory.amenities:
      return 'Amenities';
  }
}

String maintenanceStatusLabel(MaintenanceStatus value) {
  switch (value) {
    case MaintenanceStatus.open:
      return 'Open';
    case MaintenanceStatus.inProgress:
      return 'In Progress';
    case MaintenanceStatus.resolved:
      return 'Resolved';
  }
}

String visitorStatusLabel(VisitorStatus value) {
  switch (value) {
    case VisitorStatus.approved:
      return 'Approved';
    case VisitorStatus.entered:
      return 'Entered';
    case VisitorStatus.exited:
      return 'Exited';
  }
}

ParcelType parcelTypeFromString(String value) {
  return ParcelType.values.firstWhere(
    (item) => item.name == value,
    orElse: () => ParcelType.other,
  );
}

ParcelStatus parcelStatusFromString(String value) {
  return ParcelStatus.values.firstWhere(
    (item) => item.name == value,
    orElse: () => ParcelStatus.expected,
  );
}

MaintenanceCategory maintenanceCategoryFromString(String value) {
  return MaintenanceCategory.values.firstWhere(
    (item) => item.name == value,
    orElse: () => MaintenanceCategory.commonArea,
  );
}

MaintenanceStatus maintenanceStatusFromString(String value) {
  return MaintenanceStatus.values.firstWhere(
    (item) => item.name == value,
    orElse: () => MaintenanceStatus.open,
  );
}

VisitorStatus visitorStatusFromString(String value) {
  return VisitorStatus.values.firstWhere(
    (item) => item.name == value,
    orElse: () => VisitorStatus.approved,
  );
}

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  return null;
}

class ParcelRequest {
  final String id;
  final String residentUid;
  final String residentName;
  final String flatNumber;
  final ParcelType type;
  final String otherLabel;
  final DateTime expectedDate;
  final bool allowDoorDelivery;
  final ParcelStatus status;
  final DateTime? arrivedAt;
  final DateTime createdAt;

  const ParcelRequest({
    required this.id,
    required this.residentUid,
    required this.residentName,
    required this.flatNumber,
    required this.type,
    required this.otherLabel,
    required this.expectedDate,
    required this.allowDoorDelivery,
    required this.status,
    required this.arrivedAt,
    required this.createdAt,
  });

  factory ParcelRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ParcelRequest(
      id: doc.id,
      residentUid: data['residentUid'] as String? ?? '',
      residentName: data['residentName'] as String? ?? '',
      flatNumber: data['flatNumber'] as String? ?? 'Unassigned',
      type: parcelTypeFromString(data['parcelType'] as String? ?? 'other'),
      otherLabel: data['otherLabel'] as String? ?? '',
      expectedDate: _readDate(data['expectedDate']) ?? DateTime.now(),
      allowDoorDelivery: data['allowDoorDelivery'] as bool? ?? false,
      status: parcelStatusFromString(data['status'] as String? ?? 'expected'),
      arrivedAt: _readDate(data['arrivedAt']),
      createdAt: _readDate(data['createdAt']) ?? DateTime.now(),
    );
  }
}

class VisitorApproval {
  final String id;
  final String residentUid;
  final String residentName;
  final String flatNumber;
  final String guestName;
  final String phone;
  final DateTime expectedTime;
  final VisitorStatus status;
  final DateTime? enteredAt;
  final DateTime? exitedAt;
  final DateTime createdAt;

  const VisitorApproval({
    required this.id,
    required this.residentUid,
    required this.residentName,
    required this.flatNumber,
    required this.guestName,
    required this.phone,
    required this.expectedTime,
    required this.status,
    required this.enteredAt,
    required this.exitedAt,
    required this.createdAt,
  });

  factory VisitorApproval.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return VisitorApproval(
      id: doc.id,
      residentUid: data['residentUid'] as String? ?? '',
      residentName: data['residentName'] as String? ?? '',
      flatNumber: data['flatNumber'] as String? ?? 'Unassigned',
      guestName: data['guestName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      expectedTime: _readDate(data['expectedTime']) ?? DateTime.now(),
      status: visitorStatusFromString(data['status'] as String? ?? 'approved'),
      enteredAt: _readDate(data['enteredAt']),
      exitedAt: _readDate(data['exitedAt']),
      createdAt: _readDate(data['createdAt']) ?? DateTime.now(),
    );
  }
}

class MaintenanceIssue {
  final String id;
  final String residentUid;
  final String residentName;
  final String flatNumber;
  final MaintenanceCategory category;
  final String description;
  final String photoUrl;
  final MaintenanceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MaintenanceIssue({
    required this.id,
    required this.residentUid,
    required this.residentName,
    required this.flatNumber,
    required this.category,
    required this.description,
    required this.photoUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MaintenanceIssue.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return MaintenanceIssue(
      id: doc.id,
      residentUid: data['residentUid'] as String? ?? '',
      residentName: data['residentName'] as String? ?? '',
      flatNumber: data['flatNumber'] as String? ?? 'Unassigned',
      category: maintenanceCategoryFromString(
        data['category'] as String? ?? 'commonArea',
      ),
      description: data['description'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      status: maintenanceStatusFromString(data['status'] as String? ?? 'open'),
      createdAt: _readDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _readDate(data['updatedAt']) ?? DateTime.now(),
    );
  }
}
