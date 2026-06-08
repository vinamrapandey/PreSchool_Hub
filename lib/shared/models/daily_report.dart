import 'package:cloud_firestore/cloud_firestore.dart';

enum Mood { happy, okay, tired, upset, unknown }

extension MoodX on Mood {
  String toFirestoreValue() => name;
  static Mood fromString(String val) {
    return Mood.values.firstWhere(
      (e) => e.name == val,
      orElse: () => Mood.unknown,
    );
  }
}

enum MealStatus { ateWell, partial, skipped, notApplicable }

extension MealStatusX on MealStatus {
  String toFirestoreValue() => name;
  static MealStatus fromString(String val) {
    return MealStatus.values.firstWhere(
      (e) => e.name == val,
      orElse: () => MealStatus.notApplicable,
    );
  }
}

class DailyReport {
  final String reportId;
  final String studentId;
  final String classId;
  final String schoolId;
  final String date; // format: "yyyy-MM-dd"
  final Mood mood;
  final MealStatus breakfast;
  final MealStatus lunch;
  final MealStatus snack;
  final String napDuration; // e.g., "45 min", "No nap", "N/A"
  final String teacherNote;
  final String teacherUid;
  final Timestamp timestamp;

  DailyReport({
    required this.reportId,
    required this.studentId,
    required this.classId,
    required this.schoolId,
    required this.date,
    this.mood = Mood.unknown,
    this.breakfast = MealStatus.notApplicable,
    this.lunch = MealStatus.notApplicable,
    this.snack = MealStatus.notApplicable,
    this.napDuration = 'N/A',
    this.teacherNote = '',
    required this.teacherUid,
    required this.timestamp,
  });

  factory DailyReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DailyReport(
      reportId: doc.id,
      studentId: data['studentId'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      schoolId: data['schoolId'] as String? ?? '',
      date: data['date'] as String? ?? '',
      mood: MoodX.fromString(data['mood'] as String? ?? ''),
      breakfast: MealStatusX.fromString(data['breakfast'] as String? ?? ''),
      lunch: MealStatusX.fromString(data['lunch'] as String? ?? ''),
      snack: MealStatusX.fromString(data['snack'] as String? ?? ''),
      napDuration: data['napDuration'] as String? ?? 'N/A',
      teacherNote: data['teacherNote'] as String? ?? '',
      teacherUid: data['teacherUid'] as String? ?? '',
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'classId': classId,
      'schoolId': schoolId,
      'date': date,
      'mood': mood.toFirestoreValue(),
      'breakfast': breakfast.toFirestoreValue(),
      'lunch': lunch.toFirestoreValue(),
      'snack': snack.toFirestoreValue(),
      'napDuration': napDuration,
      'teacherNote': teacherNote,
      'teacherUid': teacherUid,
      'timestamp': timestamp,
    };
  }
}
