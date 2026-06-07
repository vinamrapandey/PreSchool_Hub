import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolClass {
  final String classId;
  final String schoolId;
  final String className;
  final String teacherUid;
  final List<String> studentIds;

  SchoolClass({
    required this.classId,
    required this.schoolId,
    required this.className,
    required this.teacherUid,
    required this.studentIds,
  });

  /// Factory constructor to create a [SchoolClass] from a Firestore [DocumentSnapshot].
  factory SchoolClass.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SchoolClass(
      classId: doc.id,
      schoolId: data['schoolId'] as String? ?? '',
      className: data['className'] as String? ?? '',
      teacherUid: data['teacherUid'] as String? ?? '',
      studentIds: List<String>.from(data['studentIds'] as List<dynamic>? ?? []),
    );
  }

  /// Converts the class details into a map structure for database writes.
  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'className': className,
      'teacherUid': teacherUid,
      'studentIds': studentIds,
    };
  }

  /// Creates a copy of the school class with modified fields.
  SchoolClass copyWith({
    String? classId,
    String? schoolId,
    String? className,
    String? teacherUid,
    List<String>? studentIds,
  }) {
    return SchoolClass(
      classId: classId ?? this.classId,
      schoolId: schoolId ?? this.schoolId,
      className: className ?? this.className,
      teacherUid: teacherUid ?? this.teacherUid,
      studentIds: studentIds ?? this.studentIds,
    );
  }
}
