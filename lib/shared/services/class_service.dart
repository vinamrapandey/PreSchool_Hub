import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firebase_constants.dart';
import '../models/school_class.dart';

class ClassService {
  final FirebaseFirestore _firestore;

  ClassService(this._firestore);

  /// Resolves the class assigned to a specific teacher. Returns null if none.
  Future<SchoolClass?> getClassByTeacher(String teacherUid) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.kColClasses)
          .where('teacherUid', isEqualTo: teacherUid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return SchoolClass.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Retrieves all classes operating in a specific school.
  Future<List<SchoolClass>> getClassesBySchool(String schoolId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.kColClasses)
          .where('schoolId', isEqualTo: schoolId)
          .get();

      return querySnapshot.docs
          .map((doc) => SchoolClass.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for [ClassService] enabling dependency injection.
final classServiceProvider = Provider<ClassService>((ref) {
  return ClassService(FirebaseFirestore.instance);
});
