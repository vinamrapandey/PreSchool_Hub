import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/attendance_record.dart';
import '../../../shared/models/student.dart';
import '../../../shared/services/attendance_service.dart';
import '../../../shared/services/student_service.dart';
import 'teacher_dashboard_screen.dart';

class TeacherAttendanceTab extends ConsumerStatefulWidget {
  const TeacherAttendanceTab({super.key});

  @override
  ConsumerState<TeacherAttendanceTab> createState() => _TeacherAttendanceTabState();
}

class _TeacherAttendanceTabState extends ConsumerState<TeacherAttendanceTab> {
  late DateTime _selectedDate;
  final Map<String, AttendanceStatus> _tempSelections = {};
  bool _isSaving = false;
  Future<List<AttendanceRecord>>? _existingRecordsFuture;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadExistingRecords();
  }

  void _loadExistingRecords() {
    final classState = ref.read(teacherClassProvider).value;
    if (classState == null) return;
    
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final attendanceService = ref.read(attendanceServiceProvider);
    
    setState(() {
      _existingRecordsFuture = attendanceService.getAttendanceByDate(
        classState.schoolId,
        classState.classId,
        formattedDate,
      );
      _tempSelections.clear();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadExistingRecords();
    }
  }

  Future<void> _submitAttendance(List<Student> students) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final classState = ref.read(teacherClassProvider).value;
    if (classState == null || currentUser == null) return;

    setState(() {
      _isSaving = true;
    });

    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final attendanceService = ref.read(attendanceServiceProvider);

    final records = students.map((student) {
      final status = _tempSelections[student.studentId] ?? AttendanceStatus.present;
      return AttendanceRecord(
        recordId: '', // auto-generated
        studentId: student.studentId,
        classId: student.classId,
        schoolId: student.schoolId,
        date: formattedDate,
        status: status,
        markedByUid: currentUser.uid,
        timestamp: Timestamp.now(),
      );
    }).toList();

    try {
      await attendanceService.markAttendance(records);
      _loadExistingRecords();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance submitted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit attendance: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classAsync = ref.watch(teacherClassProvider);

    return classAsync.when(
      data: (schoolClass) {
        if (schoolClass == null) {
          return const Center(child: Text('No class assigned to your account.'));
        }

        return Column(
          children: [
            // Date Picker Header Card
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance Date',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yyyy').format(_selectedDate),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_today_rounded, size: 18),
                      label: const Text('Change'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: const Size(80, 36),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main List Content
            Expanded(
              child: FutureBuilder<List<AttendanceRecord>>(
                future: _existingRecordsFuture,
                builder: (context, recordsSnapshot) {
                  if (recordsSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (recordsSnapshot.hasError) {
                    return Center(
                      child: Text('Error loading attendance: ${recordsSnapshot.error}'),
                    );
                  }

                  final existingRecords = recordsSnapshot.data ?? [];
                  final isAlreadyMarked = existingRecords.isNotEmpty;

                  return StreamBuilder<List<Student>>(
                    stream: ref.read(studentServiceProvider).getStudentsByClass(
                          schoolClass.schoolId,
                          schoolClass.classId,
                        ),
                    builder: (context, studentsSnapshot) {
                      if (studentsSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final students = studentsSnapshot.data ?? [];

                      if (students.isEmpty) {
                        return const Center(child: Text('No students in this class.'));
                      }

                      if (isAlreadyMarked) {
                        return _buildReadOnlyList(students, existingRecords, theme);
                      } else {
                        return _buildInteractiveList(students, theme);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  /// 1. Read-Only Attendance display list
  Widget _buildReadOnlyList(
    List<Student> students,
    List<AttendanceRecord> records,
    ThemeData theme,
  ) {
    final recordsMap = {for (var r in records) r.studentId: r.status};

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: theme.colorScheme.primary.withAlpha(20),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 18),
              const SizedBox(width: 8),
              Text(
                'Attendance Already Marked for this day.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              final status = recordsMap[student.studentId] ?? AttendanceStatus.present;

              Color badgeColor;
              String label;
              switch (status) {
                case AttendanceStatus.present:
                  badgeColor = Colors.green;
                  label = 'PRESENT';
                  break;
                case AttendanceStatus.absent:
                  badgeColor = Colors.red;
                  label = 'ABSENT';
                  break;
                case AttendanceStatus.late:
                  badgeColor = Colors.orange;
                  label = 'LATE';
                  break;
              }

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  child: Text(student.name.isNotEmpty ? student.name[0] : 'S'),
                ),
                title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor.withAlpha(40),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: badgeColor, width: 1.5),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 2. Interactive marking list
  Widget _buildInteractiveList(List<Student> students, ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              final selectedStatus = _tempSelections[student.studentId] ?? AttendanceStatus.present;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  child: Text(student.name.isNotEmpty ? student.name[0] : 'S'),
                ),
                title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Tap buttons to mark'),
                trailing: ToggleButtons(
                  borderRadius: BorderRadius.circular(8),
                  constraints: const BoxConstraints(minHeight: 36, minWidth: 46),
                  isSelected: [
                    selectedStatus == AttendanceStatus.present,
                    selectedStatus == AttendanceStatus.absent,
                    selectedStatus == AttendanceStatus.late,
                  ],
                  onPressed: (toggleIndex) {
                    setState(() {
                      if (toggleIndex == 0) {
                        _tempSelections[student.studentId] = AttendanceStatus.present;
                      } else if (toggleIndex == 1) {
                        _tempSelections[student.studentId] = AttendanceStatus.absent;
                      } else {
                        _tempSelections[student.studentId] = AttendanceStatus.late;
                      }
                    });
                  },
                  children: const [
                    Text('P', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('A', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('L', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
        ),
        
        // Submit button container
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isSaving
              ? const CircularProgressIndicator()
              : ElevatedButton.icon(
                  onPressed: () => _submitAttendance(students),
                  icon: const Icon(Icons.done_all_rounded),
                  label: const Text('Submit Attendance'),
                ),
        ),
      ],
    );
  }
}
