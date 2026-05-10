// ============================================================
// FIRESTORE DATA MODEL — Apartment Secretary
// ============================================================
// Notation:
//   Collection  →  /collection_name
//   Document    →  {docId}
//   Subcollection → indented under parent doc
// ============================================================

// ------------------------------------------------------------
// 1. USERS
// /users/{uid}
// ------------------------------------------------------------
// {
//   uid:            String,   // same as Firebase Auth UID (doc ID)
//   email:          String,
//   displayName:    String,
//   phoneNumber:    String,
//   photoUrl:       String?,
//   role:           String,   // 'resident' | 'secretary' | 'security'
//   apartmentId:    String?,  // FK → /apartments/{apartmentId}  (residents only)
//   flatNumber:     String?,  // denormalized for quick display
//   isApproved:     bool,     // secretary must approve new residents
//   fcmToken:       String?,  // for push notifications
//   createdAt:      Timestamp,
//   updatedAt:      Timestamp,
// }

// ------------------------------------------------------------
// 2. APARTMENTS / FLATS
// /apartments/{apartmentId}
// ------------------------------------------------------------
// {
//   apartmentId:    String,   // doc ID, e.g. "A-101"
//   block:          String,   // e.g. "A", "B", "C"
//   flatNumber:     String,   // e.g. "101"
//   floor:          int,
//   ownerUid:       String?,  // FK → /users/{uid}
//   residentUids:   List<String>, // owner + family members / tenants
//   isOccupied:     bool,
//   ownerName:      String?,  // denormalized
//   ownerPhone:     String?,  // denormalized
//   vehicleNumbers: List<String>,
//   parkingSlot:    String?,
//   createdAt:      Timestamp,
//   updatedAt:      Timestamp,
// }

// ------------------------------------------------------------
// 3. PARCELS
// /parcels/{parcelId}
// ------------------------------------------------------------
// {
//   parcelId:       String,   // doc ID (auto-generated)
//   apartmentId:    String,   // FK → /apartments
//   residentUid:    String,   // FK → /users (recipient)
//   flatNumber:     String,   // denormalized
//   recipientName:  String,
//   senderName:     String?,
//   courierCompany: String?,
//   trackingNumber: String?,
//   description:    String?,
//   photoUrl:       String?,  // photo taken by security at receipt
//   status:         String,   // 'received' | 'notified' | 'collected'
//   receivedAt:     Timestamp,
//   notifiedAt:     Timestamp?,
//   collectedAt:    Timestamp?,
//   receivedByUid:  String,   // security guard who logged it
//   collectedByUid: String?,
// }

// ------------------------------------------------------------
// 4. VISITORS
// /visitors/{visitorId}
// ------------------------------------------------------------
// {
//   visitorId:      String,   // doc ID (auto-generated)
//   name:           String,
//   phoneNumber:    String?,
//   vehicleNumber:  String?,
//   purposeOfVisit: String,   // 'guest' | 'delivery' | 'service' | 'other'
//   purposeNote:    String?,
//   photoUrl:       String?,
//   apartmentId:    String,   // visiting which flat
//   flatNumber:     String,   // denormalized
//   residentUid:    String,   // FK → /users (host)
//   approvalStatus: String,   // 'pending' | 'approved' | 'denied'
//   approvedByUid:  String?,  // resident who approved
//   checkedInAt:    Timestamp?,
//   checkedOutAt:   Timestamp?,
//   loggedByUid:    String,   // security guard
//   createdAt:      Timestamp,
// }

// ------------------------------------------------------------
// 5. MAINTENANCE ISSUES
// /maintenance_issues/{issueId}
// ------------------------------------------------------------
// {
//   issueId:        String,   // doc ID (auto-generated)
//   title:          String,
//   description:    String,
//   category:       String,   // 'plumbing' | 'electrical' | 'lift' | 'common_area' | 'security' | 'other'
//   priority:       String,   // 'low' | 'medium' | 'high' | 'urgent'
//   status:         String,   // 'open' | 'in_progress' | 'resolved' | 'closed'
//   photoUrls:      List<String>,
//   apartmentId:    String?,  // null if it's a common-area issue
//   flatNumber:     String?,
//   reportedByUid:  String,   // FK → /users
//   reportedByName: String,   // denormalized
//   assignedTo:     String?,  // name of technician / vendor
//   resolvedByUid:  String?,  // secretary who marked resolved
//   createdAt:      Timestamp,
//   updatedAt:      Timestamp,
//   resolvedAt:     Timestamp?,
//
//   // Subcollection:
//   // /maintenance_issues/{issueId}/comments/{commentId}
//   //   commentId:    String
//   //   authorUid:    String
//   //   authorName:   String
//   //   text:         String
//   //   createdAt:    Timestamp
// }

// ------------------------------------------------------------
// 6. MEETING NOTICES
// /meeting_notices/{noticeId}
// ------------------------------------------------------------
// {
//   noticeId:       String,   // doc ID (auto-generated)
//   title:          String,
//   body:           String,
//   meetingDate:    Timestamp,
//   venue:          String,
//   agenda:         List<String>,
//   attachmentUrl:  String?,
//   targetRoles:    List<String>, // ['resident'] | ['resident','secretary'] | etc.
//   publishedByUid: String,   // secretary who posted
//   publishedByName:String,   // denormalized
//   isPublished:    bool,
//   createdAt:      Timestamp,
//   updatedAt:      Timestamp,
//
//   // Subcollection:
//   // /meeting_notices/{noticeId}/acknowledgements/{uid}
//   //   uid:          String
//   //   acknowledgedAt: Timestamp
// }

// ============================================================
// FIRESTORE SECURITY RULES SUMMARY (implement in Firebase Console)
// ============================================================
//
// users:
//   - read:  authenticated users (own doc) | secretary (all)
//   - write: own doc only | secretary can update isApproved
//
// apartments:
//   - read:  authenticated users
//   - write: secretary only
//
// parcels:
//   - read:  owner resident | secretary | security
//   - write: security (create) | secretary (update status) | resident (update collectedAt)
//
// visitors:
//   - read:  resident (own flat) | secretary | security
//   - write: security (create/update) | resident (update approvalStatus)
//
// maintenance_issues:
//   - read:  reporter | secretary | security
//   - write: resident (create) | secretary (update status) | any authenticated (comment)
//
// meeting_notices:
//   - read:  authenticated users (if role in targetRoles)
//   - write: secretary only
// ============================================================
