import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingModel {
  final String id;
  final String title;
  final List<String> agenda;   // one string per agenda point
  final DateTime meetingDate;
  final String venue;
  final String createdByUid;
  final String createdByName;
  final DateTime createdAt;
  final bool notificationSent;

  const MeetingModel({
    required this.id,
    required this.title,
    required this.agenda,
    required this.meetingDate,
    required this.venue,
    required this.createdByUid,
    required this.createdByName,
    required this.createdAt,
    required this.notificationSent,
  });

  factory MeetingModel.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return MeetingModel(
      id:               doc.id,
      title:            m['title']            ?? '',
      agenda:           List<String>.from(m['agenda'] ?? []),
      meetingDate:      (m['meetingDate'] as Timestamp).toDate(),
      venue:            m['venue']            ?? '',
      createdByUid:     m['createdByUid']     ?? '',
      createdByName:    m['createdByName']    ?? '',
      createdAt:        (m['createdAt'] as Timestamp).toDate(),
      notificationSent: m['notificationSent'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'title':            title,
    'agenda':           agenda,
    'meetingDate':      Timestamp.fromDate(meetingDate),
    'venue':            venue,
    'createdByUid':     createdByUid,
    'createdByName':    createdByName,
    'createdAt':        Timestamp.fromDate(createdAt),
    'notificationSent': notificationSent,
  };
}
