import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/firebase_constants.dart';
import '../../../shared/models/school_class.dart';
import '../../../shared/models/student.dart';
import '../../../shared/services/class_service.dart';
import '../../../shared/services/student_service.dart';
import 'admin_dashboard_screen.dart';

class AdminStudentsTab extends ConsumerWidget {
  final String schoolId;

  const AdminStudentsTab({super.key, required this.schoolId});

  void _showStudentForm(BuildContext context, WidgetRef ref, [Student? student]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StudentFormBottomSheet(
        schoolId: schoolId,
        student: student,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final studentService = ref.read(studentServiceProvider);

    return Scaffold(
      body: StreamBuilder<List<Student>>(
        stream: studentService.getStudentsBySchool(schoolId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading students: ${snapshot.error}'));
          }

          final students = snapshot.data ?? [];

          if (students.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_outline_rounded, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No students registered yet.', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('Click the + button to add a new student profile.'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              final dobStr = DateFormat.yMMMd().format(student.dateOfBirth.toDate());

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                      style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('DOB: $dobStr\nClass ID: ${student.classId}'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    onPressed: () => _showStudentForm(context, ref, student),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStudentForm(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class StudentFormBottomSheet extends ConsumerStatefulWidget {
  final String schoolId;
  final Student? student;

  const StudentFormBottomSheet({
    super.key,
    required this.schoolId,
    this.student,
  });

  @override
  ConsumerState<StudentFormBottomSheet> createState() => _StudentFormBottomSheetState();
}

class _StudentFormBottomSheetState extends ConsumerState<StudentFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _parentEmailController = TextEditingController();
  
  DateTime? _selectedDob;
  String? _selectedClassId;
  List<SchoolClass> _classes = [];
  bool _isLoadingClasses = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      _nameController.text = widget.student!.name;
      _selectedDob = widget.student!.dateOfBirth.toDate();
      _selectedClassId = widget.student!.classId.isNotEmpty ? widget.student!.classId : null;
      _resolveParentEmail();
    }
    _loadClasses();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _parentEmailController.dispose();
    super.dispose();
  }

  /// Looks up the parent's email dynamically from Firestore if parentUids are present
  Future<void> _resolveParentEmail() async {
    if (widget.student?.parentUids.isNotEmpty ?? false) {
      try {
        final parentDoc = await FirebaseFirestore.instance
            .collection(FirebaseConstants.kColUsers)
            .doc(widget.student!.parentUids.first)
            .get();
        if (parentDoc.exists && mounted) {
          setState(() {
            _parentEmailController.text = parentDoc.data()?['email'] as String? ?? '';
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _loadClasses() async {
    try {
      final classes = await ref.read(classServiceProvider).getClassesBySchool(widget.schoolId);
      if (mounted) {
        setState(() {
          _classes = classes;
          _isLoadingClasses = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingClasses = false;
        });
      }
    }
  }

  Future<void> _selectDob(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime.now().subtract(const Duration(days: 365 * 3)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 8)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Date of Birth.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final name = _nameController.text.trim();
    final parentEmail = _parentEmailController.text.trim();
    final List<String> parentUids = [];

    try {
      // 1. Link parentUid if email provided
      if (parentEmail.isNotEmpty) {
        final parentQuery = await FirebaseFirestore.instance
            .collection(FirebaseConstants.kColUsers)
            .where('email', isEqualTo: parentEmail)
            .where('role', isEqualTo: 'parent')
            .limit(1)
            .get();

        if (parentQuery.docs.isNotEmpty) {
          parentUids.add(parentQuery.docs.first.id);
        } else {
          // Warning SnackBar, but continue with saving
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Warning: No parent registered with email $parentEmail. Linked parent will be empty.'),
                backgroundColor: Colors.amber.shade800,
              ),
            );
          }
        }
      }

      final studentService = ref.read(studentServiceProvider);
      
      if (widget.student == null) {
        // Create new
        final newStudent = Student(
          studentId: '', // auto-generated
          name: name,
          dateOfBirth: Timestamp.fromDate(_selectedDob!),
          classId: _selectedClassId ?? '',
          schoolId: widget.schoolId,
          parentUids: parentUids,
          photoUrl: '',
          notes: '',
        );
        await studentService.addStudent(newStudent);
      } else {
        // Edit existing
        final updatedStudent = widget.student!.copyWith(
          name: name,
          dateOfBirth: Timestamp.fromDate(_selectedDob!),
          classId: _selectedClassId ?? '',
          parentUids: parentUids.isNotEmpty ? parentUids : widget.student!.parentUids,
        );
        await studentService.updateStudent(updatedStudent);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.student == null ? 'Student added successfully!' : 'Student updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
            backgroundColor: Colors.red,
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

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24.0,
        right: 24.0,
        top: 24.0,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.student == null ? 'Add Student' : 'Edit Student',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Student Full Name',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the student\'s name';
                  }
                  return null;
                },
                enabled: !_isSaving,
              ),
              const SizedBox(height: 16),

              // Date of Birth selector
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cake_rounded),
                title: Text(
                  _selectedDob == null ? 'Select Date of Birth' : DateFormat.yMMMd().format(_selectedDob!),
                  style: TextStyle(
                    fontWeight: _selectedDob == null ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: _isSaving ? null : () => _selectDob(context),
              ),
              const Divider(),
              const SizedBox(height: 8),

              // Class assignment Selector
              _isLoadingClasses
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: _selectedClassId,
                      decoration: const InputDecoration(
                        labelText: 'Assign Class',
                        prefixIcon: Icon(Icons.class_rounded),
                      ),
                      items: _classes.map((c) {
                        return DropdownMenuItem<String>(
                          value: c.classId,
                          child: Text(c.className),
                        );
                      }).toList(),
                      onChanged: _isSaving
                          ? null
                          : (val) {
                              setState(() {
                                _selectedClassId = val;
                              });
                            },
                      hint: const Text('Select class (optional)'),
                    ),
              const SizedBox(height: 16),

              // Parent Email field
              TextFormField(
                controller: _parentEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Parent Email',
                  hintText: 'Link child to registered parent account',
                  prefixIcon: Icon(Icons.email_rounded),
                ),
                enabled: !_isSaving,
              ),
              const SizedBox(height: 32),

              // Action buttons
              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _save,
                          child: const Text('Save Student'),
                        ),
                      ],
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
