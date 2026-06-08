import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firebase_constants.dart';
import '../../../shared/models/school_class.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/notice.dart';
import '../../../shared/models/student.dart';
import '../../../shared/services/class_service.dart';
import '../../../shared/services/student_service.dart';

final classesBySchoolProvider = FutureProvider.family.autoDispose<List<SchoolClass>, String>((ref, schoolId) async {
  final service = ref.read(classServiceProvider);
  return service.getClassesBySchool(schoolId);
});

final teachersBySchoolProvider = FutureProvider.family.autoDispose<List<AppUser>, String>((ref, schoolId) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection(FirebaseConstants.kColUsers)
      .where('schoolId', isEqualTo: schoolId)
      .where('role', isEqualTo: 'teacher')
      .get();
  return querySnapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
});

final noticesBySchoolProvider = FutureProvider.family.autoDispose<List<Notice>, String>((ref, schoolId) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection(FirebaseConstants.kColNotices)
      .where('schoolId', isEqualTo: schoolId)
      .get();
  return querySnapshot.docs.map((doc) => Notice.fromFirestore(doc)).toList();
});

final studentsBySchoolProvider = FutureProvider.family.autoDispose<List<Student>, String>((ref, schoolId) async {
  final service = ref.read(studentServiceProvider);
  final stream = service.getStudentsBySchool(schoolId);
  return stream.first;
});
