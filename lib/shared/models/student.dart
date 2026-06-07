import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String studentId;
  final String name;
  final Timestamp dateOfBirth;
  final String classId;
  final String schoolId;
  final List<String> parentUids;
  final String? photoUrl;
  final String? notes;

  Student({
    required this.studentId,
    required this.name,
    required this.dateOfBirth,
    required this.classId,
    required this.schoolId,
    required this.parentUids,
    this.photoUrl,
    this.notes,
  });

  /// Factory constructor to create a [Student] from a Firestore [DocumentSnapshot].
  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Student(
      studentId: doc.id,
      name: data['name'] as String? ?? '',
      dateOfBirth: data['dateOfBirth'] as Timestamp? ?? Timestamp.now(),
      classId: data['classId'] as String? ?? '',
      schoolId: data['schoolId'] as String? ?? '',
      parentUids: List<String>.from(data['parentUids'] as List<dynamic>? ?? []),
      photoUrl: data['photoUrl'] as String?,
      notes: data['notes'] as String?,
    );
  }

  /// Converts the student details into a map structure for database writes.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dateOfBirth': dateOfBirth,
      'classId': classId,
      'schoolId': schoolId,
      'parentUids': parentUids,
      'photoUrl': photoUrl,
      'notes': notes,
    };
  }

  /// Creates a copy of the student with modified fields.
  Student copyWith({
    String? studentId,
    String? name,
    Timestamp? dateOfBirth,
    String? classId,
    String? schoolId,
    List<String>? parentUids,
    String? photoUrl,
    String? notes,
  }) {
    return Student(
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      classId: classId ?? this.classId,
      schoolId: schoolId ?? this.schoolId,
      parentUids: parentUids ?? this.parentUids,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
    );
  }
}
