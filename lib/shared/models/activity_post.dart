import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityPost {
  final String postId;
  final String schoolId;
  final String classId;
  final String teacherUid;
  final String teacherName;
  final String content;
  final List<String> mediaUrls;
  final Timestamp timestamp;
  final List<String> targetRoles;
  final String activityType; // e.g. "Art", "Story", "Outdoor", "Music", "Learning", "Meal"

  ActivityPost({
    required this.postId,
    required this.schoolId,
    required this.classId,
    required this.teacherUid,
    required this.teacherName,
    required this.content,
    required this.mediaUrls,
    required this.timestamp,
    required this.targetRoles,
    this.activityType = 'General',
  });

  /// Factory constructor to create an [ActivityPost] from a Firestore [DocumentSnapshot].
  factory ActivityPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ActivityPost(
      postId: doc.id,
      schoolId: data['schoolId'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      teacherUid: data['teacherUid'] as String? ?? '',
      teacherName: data['teacherName'] as String? ?? '',
      content: data['content'] as String? ?? '',
      mediaUrls: List<String>.from(data['mediaUrls'] as List<dynamic>? ?? []),
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
      targetRoles: List<String>.from(data['targetRoles'] as List<dynamic>? ?? []),
      activityType: data['activityType'] as String? ?? 'General',
    );
  }

  /// Converts the post details into a map structure for database writes.
  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'classId': classId,
      'teacherUid': teacherUid,
      'teacherName': teacherName,
      'content': content,
      'mediaUrls': mediaUrls,
      'timestamp': timestamp,
      'targetRoles': targetRoles,
      'activityType': activityType,
    };
  }

  /// Creates a copy of the activity post with modified fields.
  ActivityPost copyWith({
    String? postId,
    String? schoolId,
    String? classId,
    String? teacherUid,
    String? teacherName,
    String? content,
    List<String>? mediaUrls,
    Timestamp? timestamp,
    List<String>? targetRoles,
    String? activityType,
  }) {
    return ActivityPost(
      postId: postId ?? this.postId,
      schoolId: schoolId ?? this.schoolId,
      classId: classId ?? this.classId,
      teacherUid: teacherUid ?? this.teacherUid,
      teacherName: teacherName ?? this.teacherName,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      timestamp: timestamp ?? this.timestamp,
      targetRoles: targetRoles ?? this.targetRoles,
      activityType: activityType ?? this.activityType,
    );
  }
}
