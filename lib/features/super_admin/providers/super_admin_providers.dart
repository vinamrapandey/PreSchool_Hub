import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firebase_constants.dart';
import '../../../shared/models/school_branding.dart';

/// Provider to fetch all schools dynamically.
final allSchoolsProvider = StreamProvider.autoDispose<List<SchoolBranding>>((ref) {
  return FirebaseFirestore.instance
      .collection(FirebaseConstants.kColSchools)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => SchoolBranding.fromFirestore(doc)).toList());
});

/// Fetches platform-wide stats (total students across all schools)
final platformStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final firestore = FirebaseFirestore.instance;
  
  final schoolsSnap = await firestore.collection(FirebaseConstants.kColSchools).get();
  final totalSchools = schoolsSnap.docs.length;
  final activeSchools = schoolsSnap.docs.where((doc) => doc.data()['isActive'] == true).length;
  final inactiveSchools = totalSchools - activeSchools;
  
  final studentsSnap = await firestore.collection(FirebaseConstants.kColStudents).get();
  final totalStudents = studentsSnap.docs.length;

  return {
    'totalSchools': totalSchools,
    'activeSchools': activeSchools,
    'inactiveSchools': inactiveSchools,
    'totalStudents': totalStudents,
  };
});
