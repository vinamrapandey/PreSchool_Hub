import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/student.dart';
import '../../../../shared/models/school_class.dart';
import '../../../../shared/services/student_service.dart';
import '../../../../shared/services/class_service.dart';
import '../../providers/admin_providers.dart';
import '../components/add_student_form.dart';

class AdminStudentsTab extends ConsumerStatefulWidget {
  final String schoolId;
  const AdminStudentsTab({super.key, required this.schoolId});

  @override
  ConsumerState<AdminStudentsTab> createState() => _AdminStudentsTabState();
}

class _AdminStudentsTabState extends ConsumerState<AdminStudentsTab> {
  String _searchQuery = '';
  String? _selectedClassId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final studentsAsync = ref.watch(studentsBySchoolProvider(widget.schoolId));
    final classesAsync = ref.watch(classesBySchoolProvider(widget.schoolId));

    return Scaffold(
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search students...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                classesAsync.when(
                  data: (classes) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: const Text('All Classes'),
                              selected: _selectedClassId == null,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedClassId = null);
                                }
                              },
                            ),
                          ),
                          ...classes.map((c) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: FilterChip(
                                  label: Text(c.className),
                                  selected: _selectedClassId == c.classId,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedClassId = selected ? c.classId : null;
                                    });
                                  },
                                ),
                              )),
                        ],
                      ),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Error loading classes'),
                ),
              ],
            ),
          ),
          
          // Student List
          Expanded(
            child: studentsAsync.when(
              data: (students) {
                // Filter students
                final filtered = students.where((s) {
                  final matchesSearch = s.name.toLowerCase().contains(_searchQuery);
                  final matchesClass = _selectedClassId == null || s.classId == _selectedClassId;
                  return matchesSearch && matchesClass;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No students found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final student = filtered[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: student.photoUrl != null && student.photoUrl!.isNotEmpty
                              ? NetworkImage(student.photoUrl!)
                              : null,
                          child: student.photoUrl == null || student.photoUrl!.isEmpty
                              ? Text(student.name[0].toUpperCase())
                              : null,
                        ),
                        title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Class ID: ${student.classId}'), // Ideally we map this to Class Name
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          // TODO: Navigate to Student Detail Screen
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (ctx) => AddStudentForm(schoolId: widget.schoolId),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Student'),
      ),
    );
  }
}
