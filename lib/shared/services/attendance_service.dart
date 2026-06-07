import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firebase_constants.dart';
import '../models/attendance_record.dart';

class AttendanceService {
  final FirebaseFirestore _firestore;

  AttendanceService(this._firestore);

  /// Saves a list of attendance records using a Firestore write batch.
  Future<void> markAttendance(List<AttendanceRecord> records) async {
    try {
      final batch = _firestore.batch();

      for (final record in records) {
        final docRef = record.recordId.isEmpty
            ? _firestore.collection(FirebaseConstants.kColAttendance).doc()
            : _firestore.collection(FirebaseConstants.kColAttendance).doc(record.recordId);
            
        final recordToSave = record.recordId.isEmpty
            ? record.copyWith(recordId: docRef.id)
            : record;

        batch.set(docRef, recordToSave.toMap(), SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// Retrieves attendance records for a specific date.
  Future<List<AttendanceRecord>> getAttendanceByDate(
    String schoolId,
    String classId,
    String date,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseConstants.kColAttendance)
          .where('schoolId', isEqualTo: schoolId)
          .where('classId', isEqualTo: classId)
          .where('date', isEqualTo: date)
          .get();

      return querySnapshot.docs
          .map((doc) => AttendanceRecord.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Streams attendance records for a specific student for a given year and month (format: "yyyy-MM").
  Stream<List<AttendanceRecord>> getStudentMonthlyAttendance(
    String studentId,
    String yearMonth,
  ) {
    // Strings in yyyy-MM-dd sorted format allow range checks (starts with yearMonth)
    final startRange = '$yearMonth-01';
    final endRange = '$yearMonth-31';

    return _firestore
        .collection(FirebaseConstants.kColAttendance)
        .where('studentId', isEqualTo: studentId)
        .where('date', isGreaterThanOrEqualTo: startRange)
        .where('date', isLessThanOrEqualTo: endRange)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceRecord.fromFirestore(doc))
            .toList());
  }
}

/// Provider for [AttendanceService] enabling dependency injection.
final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService(FirebaseFirestore.instance);
});
