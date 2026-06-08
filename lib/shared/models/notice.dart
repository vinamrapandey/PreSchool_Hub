import 'package:cloud_firestore/cloud_firestore.dart';

class Notice {
  final String noticeId;
  final String schoolId;
  final String title;
  final String body;
  final List<String> targetRoles;
  final String createdByUid;
  final Timestamp timestamp;
  final bool isActive;
  final bool isPinned;
  final String? targetClassId;

  Notice({
    required this.noticeId,
    required this.schoolId,
    required this.title,
    required this.body,
    required this.targetRoles,
    required this.createdByUid,
    required this.timestamp,
    this.isActive = true,
    this.isPinned = false,
    this.targetClassId,
  });

  /// Factory constructor to create a [Notice] from a Firestore [DocumentSnapshot].
  factory Notice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Notice(
      noticeId: doc.id,
      schoolId: data['schoolId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      targetRoles: List<String>.from(data['targetRoles'] as List<dynamic>? ?? []),
      createdByUid: data['createdByUid'] as String? ?? '',
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
      isActive: data['isActive'] as bool? ?? true,
      isPinned: data['isPinned'] as bool? ?? false,
      targetClassId: data['targetClassId'] as String?,
    );
  }

  /// Converts the notice details into a map structure for database writes.
  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'title': title,
      'body': body,
      'targetRoles': targetRoles,
      'createdByUid': createdByUid,
      'timestamp': timestamp,
      'isActive': isActive,
      'isPinned': isPinned,
      'targetClassId': targetClassId,
    };
  }

  /// Creates a copy of the notice with modified fields.
  Notice copyWith({
    String? noticeId,
    String? schoolId,
    String? title,
    String? body,
    List<String>? targetRoles,
    String? createdByUid,
    Timestamp? timestamp,
    bool? isActive,
    bool? isPinned,
    String? targetClassId,
  }) {
    return Notice(
      noticeId: noticeId ?? this.noticeId,
      schoolId: schoolId ?? this.schoolId,
      title: title ?? this.title,
      body: body ?? this.body,
      targetRoles: targetRoles ?? this.targetRoles,
      createdByUid: createdByUid ?? this.createdByUid,
      timestamp: timestamp ?? this.timestamp,
      isActive: isActive ?? this.isActive,
      isPinned: isPinned ?? this.isPinned,
      targetClassId: targetClassId ?? this.targetClassId,
    );
  }
}
