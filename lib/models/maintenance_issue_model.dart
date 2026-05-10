import 'package:cloud_firestore/cloud_firestore.dart';

enum IssueCategory { plumbing, electrical, commonArea, amenities }

extension IssueCategoryX on IssueCategory {
  String get value {
    switch (this) {
      case IssueCategory.plumbing:    return 'plumbing';
      case IssueCategory.electrical:  return 'electrical';
      case IssueCategory.commonArea:  return 'common_area';
      case IssueCategory.amenities:   return 'amenities';
    }
  }

  String get label {
    switch (this) {
      case IssueCategory.plumbing:    return 'Plumbing';
      case IssueCategory.electrical:  return 'Electrical';
      case IssueCategory.commonArea:  return 'Common Area';
      case IssueCategory.amenities:   return 'Amenities';
    }
  }

  static IssueCategory fromString(String s) {
    switch (s) {
      case 'electrical':   return IssueCategory.electrical;
      case 'common_area':  return IssueCategory.commonArea;
      case 'amenities':    return IssueCategory.amenities;
      default:             return IssueCategory.plumbing;
    }
  }
}

enum IssueStatus { open, inProgress, resolved }

extension IssueStatusX on IssueStatus {
  String get value {
    switch (this) {
      case IssueStatus.open:       return 'open';
      case IssueStatus.inProgress: return 'in_progress';
      case IssueStatus.resolved:   return 'resolved';
    }
  }

  String get label {
    switch (this) {
      case IssueStatus.open:       return 'Open';
      case IssueStatus.inProgress: return 'In Progress';
      case IssueStatus.resolved:   return 'Resolved';
    }
  }

  static IssueStatus fromString(String s) {
    switch (s) {
      case 'in_progress': return IssueStatus.inProgress;
      case 'resolved':    return IssueStatus.resolved;
      default:            return IssueStatus.open;
    }
  }
}

class MaintenanceIssue {
  final String id;
  final String title;
  final String description;
  final IssueCategory category;
  final IssueStatus status;
  final List<String> photoUrls;
  final String reportedByUid;
  final String reportedByName;
  final String flatNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  const MaintenanceIssue({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.photoUrls,
    required this.reportedByUid,
    required this.reportedByName,
    required this.flatNumber,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
  });

  factory MaintenanceIssue.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return MaintenanceIssue(
      id:              doc.id,
      title:           m['title']           ?? '',
      description:     m['description']     ?? '',
      category:        IssueCategoryX.fromString(m['category'] ?? ''),
      status:          IssueStatusX.fromString(m['status']   ?? ''),
      photoUrls:       List<String>.from(m['photoUrls'] ?? []),
      reportedByUid:   m['reportedByUid']   ?? '',
      reportedByName:  m['reportedByName']  ?? '',
      flatNumber:      m['flatNumber']      ?? '',
      createdAt:       (m['createdAt'] as Timestamp).toDate(),
      updatedAt:       (m['updatedAt'] as Timestamp).toDate(),
      resolvedAt:      m['resolvedAt'] != null ? (m['resolvedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'title':           title,
    'description':     description,
    'category':        category.value,
    'status':          status.value,
    'photoUrls':       photoUrls,
    'reportedByUid':   reportedByUid,
    'reportedByName':  reportedByName,
    'flatNumber':      flatNumber,
    'createdAt':       Timestamp.fromDate(createdAt),
    'updatedAt':       Timestamp.fromDate(updatedAt),
    'resolvedAt':      resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
  };
}
