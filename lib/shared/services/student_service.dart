import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firebase_constants.dart';
import '../models/student.dart';

class StudentService {
  final FirebaseFirestore _firestore;

  StudentService(this._firestore);

  /// Streams students in a given school and class.
  Stream<List<Student>> getStudentsByClass(String schoolId, String classId) {
    return _firestore
        .collection(FirebaseConstants.kColStudents)
        .where('schoolId', isEqualTo: schoolId)
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Student.fromFirestore(doc))
            .toList());
  }

  /// Streams students associated with a parent/guardian UID.
  Stream<List<Student>> getStudentsByParentUid(String parentUid) {
    return _firestore
        .collection(FirebaseConstants.kColStudents)
        .where('parentUids', arrayContains: parentUid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Student.fromFirestore(doc))
            .toList());
  }

  /// Streams all students registered under a specific school.
  Stream<List<Student>> getStudentsBySchool(String schoolId) {
    return _firestore
        .collection(FirebaseConstants.kColStudents)
        .where('schoolId', isEqualTo: schoolId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Student.fromFirestore(doc))
            .toList());
  }

  /// Adds a new student document to Firestore.
  Future<void> addStudent(Student student) async {
    try {
      final docRef = student.studentId.isEmpty
          ? _firestore.collection(FirebaseConstants.kColStudents).doc()
          : _firestore.collection(FirebaseConstants.kColStudents).doc(student.studentId);
      
      final studentToSave = student.studentId.isEmpty
          ? student.copyWith(studentId: docRef.id)
          : student;

      await docRef.set(studentToSave.toMap());
    } catch (e) {
      rethrow;
    }
  }

  /// Updates an existing student document.
  Future<void> updateStudent(Student student) async {
    try {
      await _firestore
          .collection(FirebaseConstants.kColStudents)
          .doc(student.studentId)
          .update(student.toMap());
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for [StudentService] enabling dependency injection.
final studentServiceProvider = Provider<StudentService>((ref) {
  return StudentService(FirebaseFirestore.instance);
});
