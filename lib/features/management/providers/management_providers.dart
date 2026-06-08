import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/firebase_constants.dart';
import '../../../shared/models/activity_post.dart';
import '../../../shared/models/notice.dart';
import '../../../shared/models/school_class.dart';
import '../../../shared/models/app_user.dart';

/// Provider for overall school metrics
final managementOverviewStatsProvider = FutureProvider.family.autoDispose<Map<String, dynamic>, String>((ref, schoolId) async {
  final firestore = FirebaseFirestore.instance;

  // 1. Total Students Count
  final studentsQuery = await firestore
      .collection(FirebaseConstants.kColStudents)
      .where('schoolId', isEqualTo: schoolId)
      .get();
  final totalStudents = studentsQuery.docs.length;

  // 2. Total Teachers Count
  final teachersQuery = await firestore
      .collection(FirebaseConstants.kColUsers)
      .where('schoolId', isEqualTo: schoolId)
      .where('role', isEqualTo: 'teacher')
      .get();
  final totalTeachers = teachersQuery.docs.length;

  // 3. Total Classes Count
  final classesQuery = await firestore
      .collection(FirebaseConstants.kColClasses)
      .where('schoolId', isEqualTo: schoolId)
      .get();
  final totalClasses = classesQuery.docs.length;

  // 4. Today's Attendance snapshot
  final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final attendanceQuery = await firestore
      .collection(FirebaseConstants.kColAttendance)
      .where('schoolId', isEqualTo: schoolId)
      .where('date', isEqualTo: todayStr)
      .get();

  int presentCount = 0;
  int absentCount = 0;
  
  for (var doc in attendanceQuery.docs) {
    if (doc.data()['status'] == 'present') {
      presentCount++;
    } else if (doc.data()['status'] == 'absent') {
      absentCount++;
    }
  }

  final notMarkedCount = totalStudents - (presentCount + absentCount);

  double attendanceRate = 0.0;
  if (totalStudents > 0) {
    attendanceRate = (presentCount / totalStudents) * 100;
  }

  // 5. Today's Activity snapshot
  final todayStart = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
  final activityQuery = await firestore
      .collection(FirebaseConstants.kColActivities)
      .where('schoolId', isEqualTo: schoolId)
      .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
      .get();
  
  final postsToday = activityQuery.docs.length;
  final photosSharedToday = activityQuery.docs.where((d) {
    final urls = d.data()['mediaUrls'] as List<dynamic>?;
    return urls != null && urls.isNotEmpty;
  }).length;

  // Calculate Average Attendance (Mocked for now)
  final avgAttendanceThisMonth = attendanceRate > 0 ? attendanceRate - 2.0 : 84.0; 

  return {
    'totalStudents': totalStudents,
    'totalTeachers': totalTeachers,
    'totalClasses': totalClasses,
    'presentCount': presentCount,
    'absentCount': absentCount,
    'notMarkedCount': notMarkedCount > 0 ? notMarkedCount : 0,
    'attendanceRate': attendanceRate,
    'postsToday': postsToday,
    'photosSharedToday': photosSharedToday,
    'avgAttendanceThisMonth': avgAttendanceThisMonth,
    'totalNoticesThisMonth': 12, // Mocked
  };
});

/// FutureProvider resolving the last 7 days daily attendance rates for fl_chart.
final managementAttendanceTrendProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, String>((ref, schoolId) async {
  final firestore = FirebaseFirestore.instance;
  final List<Map<String, dynamic>> trendData = [];

  final studentsQuery = await firestore
      .collection(FirebaseConstants.kColStudents)
      .where('schoolId', isEqualTo: schoolId)
      .get();
  final totalStudents = studentsQuery.docs.length;

  if (totalStudents == 0) {
    return List.generate(7, (i) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      return {'date': DateFormat('dd MMM').format(date), 'rate': 100.0};
    });
  }

  final startDate = DateTime.now().subtract(const Duration(days: 6));
  final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);

  final attendanceQuery = await firestore
      .collection(FirebaseConstants.kColAttendance)
      .where('schoolId', isEqualTo: schoolId)
      .where('date', isGreaterThanOrEqualTo: startDateStr)
      .get();

  final docs = attendanceQuery.docs;

  for (int i = 0; i < 7; i++) {
    final date = DateTime.now().subtract(Duration(days: 6 - i));
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final dateLabel = DateFormat('dd MMM').format(date);

    final dailyDocs = docs.where((doc) => doc.data()['date'] == dateStr);
    final dailyPresent = dailyDocs.where((doc) => doc.data()['status'] == 'present').length;

    double dailyRate = dailyDocs.isNotEmpty ? (dailyPresent / totalStudents) * 100 : 100.0; 

    trendData.add({
      'date': dateLabel,
      'rate': dailyRate,
    });
  }

  return trendData;
});

final managementClassesStatusProvider = FutureProvider.family.autoDispose<List<SchoolClass>, String>((ref, schoolId) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection(FirebaseConstants.kColClasses)
      .where('schoolId', isEqualTo: schoolId)
      .get();
  return querySnapshot.docs.map((doc) => SchoolClass.fromFirestore(doc)).toList();
});

final managementNoticesProvider = FutureProvider.family.autoDispose<List<Notice>, String>((ref, schoolId) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection(FirebaseConstants.kColNotices)
      .where('schoolId', isEqualTo: schoolId)
      .get();
  return querySnapshot.docs.map((doc) => Notice.fromFirestore(doc)).toList();
});

final managementTeachersProvider = FutureProvider.family.autoDispose<List<AppUser>, String>((ref, schoolId) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection(FirebaseConstants.kColUsers)
      .where('schoolId', isEqualTo: schoolId)
      .where('role', isEqualTo: 'teacher')
      .get();
  return querySnapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
});
