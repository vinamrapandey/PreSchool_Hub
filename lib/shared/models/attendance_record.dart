import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus {
  present,
  absent,
  late,
}

extension AttendanceStatusX on AttendanceStatus {
  /// Converts the enum value to the string representation stored in Firestore.
  String toFirestoreValue() => name;

  /// Parses a string value from Firestore back into an [AttendanceStatus] enum.
  static AttendanceStatus fromString(String val) {
    switch (val) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late;
      default:
        throw ArgumentError('Invalid attendance status: $val');
    }
  }
}

class AttendanceRecord {
  final String recordId;
  final String studentId;
  final String classId;
  final String schoolId;
  final String date; // format: "yyyy-MM-dd"
  final AttendanceStatus status;
  final String markedByUid;
  final Timestamp timestamp;

  AttendanceRecord({
    required this.recordId,
    required this.studentId,
    required this.classId,
    required this.schoolId,
    required this.date,
    required this.status,
    required this.markedByUid,
    required this.timestamp,
  });

  /// Factory constructor to create an [AttendanceRecord] from a Firestore [DocumentSnapshot].
  factory AttendanceRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final statusStr = data['status'] as String? ?? 'present';
    return AttendanceRecord(
      recordId: doc.id,
      studentId: data['studentId'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      schoolId: data['schoolId'] as String? ?? '',
      date: data['date'] as String? ?? '',
      status: AttendanceStatusX.fromString(statusStr),
      markedByUid: data['markedByUid'] as String? ?? '',
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
    );
  }

  /// Converts the attendance record details into a map structure for database writes.
  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'classId': classId,
      'schoolId': schoolId,
      'date': date,
      'status': status.toFirestoreValue(),
      'markedByUid': markedByUid,
      'timestamp': timestamp,
    };
  }

  /// Creates a copy of the attendance record with modified fields.
  AttendanceRecord copyWith({
    String? recordId,
    String? studentId,
    String? classId,
    String? schoolId,
    String? date,
    AttendanceStatus? status,
    String? markedByUid,
    Timestamp? timestamp,
  }) {
    return AttendanceRecord(
      recordId: recordId ?? this.recordId,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      schoolId: schoolId ?? this.schoolId,
      date: date ?? this.date,
      status: status ?? this.status,
      markedByUid: markedByUid ?? this.markedByUid,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
