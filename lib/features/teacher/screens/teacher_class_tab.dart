import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/student.dart';
import '../../../shared/services/student_service.dart';
import 'teacher_dashboard_screen.dart';

class TeacherClassTab extends ConsumerWidget {
  const TeacherClassTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final classAsync = ref.watch(teacherClassProvider);

    return classAsync.when(
      data: (schoolClass) {
        if (schoolClass == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'No class assigned to your account. Contact school admin.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final studentService = ref.read(studentServiceProvider);

        return StreamBuilder<List<Student>>(
          stream: studentService.getStudentsByClass(
            schoolClass.schoolId,
            schoolClass.classId,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading class: ${snapshot.error}'),
              );
            }

            final students = snapshot.data ?? [];

            if (students.isEmpty) {
              return const Center(
                child: Text('No students registered in this class.'),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                mainAxisSpacing: 16.0,
                crossAxisSpacing: 16.0,
                childAspectRatio: 0.85,
              ),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withAlpha(128),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Photo or Initials Avatar
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: student.photoUrl != null && student.photoUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: student.photoUrl!,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: theme.colorScheme.surfaceContainerHigh,
                                      child: const Center(
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: theme.colorScheme.primaryContainer,
                                      child: Center(
                                        child: Text(
                                          student.name.isNotEmpty
                                              ? student.name[0].toUpperCase()
                                              : 'S',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: theme.colorScheme.primaryContainer,
                                    width: double.infinity,
                                    child: Center(
                                      child: Text(
                                        student.name.isNotEmpty
                                            ? student.name[0].toUpperCase()
                                            : 'S',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Student Name
                        Text(
                          student.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading class: $err')),
    );
  }
}
