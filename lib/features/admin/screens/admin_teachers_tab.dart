import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firebase_constants.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/school_class.dart';
import '../../../shared/services/class_service.dart';

/// Provider resolving classes associated with a school.
final schoolClassesProvider = FutureProvider.family.autoDispose<List<SchoolClass>, String>((ref, schoolId) {
  return ref.read(classServiceProvider).getClassesBySchool(schoolId);
});

class AdminTeachersTab extends ConsumerWidget {
  final String schoolId;

  const AdminTeachersTab({super.key, required this.schoolId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final classesAsync = ref.watch(schoolClassesProvider(schoolId));

    return Scaffold(
      body: StreamBuilder<List<AppUser>>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.kColUsers)
            .where('schoolId', isEqualTo: schoolId)
            .where('role', isEqualTo: 'teacher')
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => AppUser.fromFirestore(doc))
                .toList()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading teachers: ${snapshot.error}'));
          }

          final teachers = snapshot.data ?? [];

          if (teachers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('No teachers registered.', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text('Teachers are registered by the Super Admin.', textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          return classesAsync.when(
            data: (classesList) {
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount: teachers.length,
                itemBuilder: (context, index) {
                  final teacher = teachers[index];

                  // Find assigned class
                  final assignedClass = classesList.firstWhere(
                    (c) => c.teacherUid == teacher.uid,
                    orElse: () => SchoolClass(classId: '', schoolId: '', className: 'Not Assigned', teacherUid: '', studentIds: []),
                  );

                  final isAssigned = assignedClass.classId.isNotEmpty;

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        child: Text(
                          teacher.displayName.isNotEmpty ? teacher.displayName[0].toUpperCase() : 'T',
                          style: TextStyle(color: theme.colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(teacher.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(teacher.email),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAssigned ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isAssigned ? 'Class: ${assignedClass.className}' : 'Not Assigned',
                          style: TextStyle(
                            color: isAssigned ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading class assignments: $err')),
          );
        },
      ),
    );
  }
}
