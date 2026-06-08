import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/school_class.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/services/class_service.dart';
import '../../../../shared/services/user_service.dart';
import '../../providers/admin_providers.dart';
import '../components/add_teacher_form.dart';
import '../components/add_class_form.dart';

class AdminStaffTab extends ConsumerStatefulWidget {
  final String schoolId;
  const AdminStaffTab({super.key, required this.schoolId});

  @override
  ConsumerState<AdminStaffTab> createState() => _AdminStaffTabState();
}

class _AdminStaffTabState extends ConsumerState<AdminStaffTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ColoredBox(
          color: theme.colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Teachers'),
              Tab(text: 'Classes'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTeachersList(theme),
          _buildClassesList(theme),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (ctx) => AddTeacherForm(schoolId: widget.schoolId),
            );
          } else {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (ctx) => AddClassForm(schoolId: widget.schoolId),
            );
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) => Text(_tabController.index == 0 ? 'Add Teacher' : 'Add Class'),
        ),
      ),
    );
  }

  Widget _buildTeachersList(ThemeData theme) {
    final teachersAsync = ref.watch(teachersBySchoolProvider(widget.schoolId));
    final classesAsync = ref.watch(classesBySchoolProvider(widget.schoolId));

    return teachersAsync.when(
      data: (teachers) {
        if (teachers.isEmpty) {
          return const Center(child: Text('No teachers found.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80, top: 8),
          itemCount: teachers.length,
          itemBuilder: (context, index) {
            final teacher = teachers[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(teacher.displayName.isNotEmpty ? teacher.displayName[0].toUpperCase() : '?'),
                ),
                title: Text(teacher.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(teacher.email),
                trailing: classesAsync.when(
                  data: (classes) {
                    final assignedClass = classes.where((c) => c.teacherUid == teacher.uid).firstOrNull;
                    if (assignedClass != null) {
                      return Chip(label: Text(assignedClass.className), visualDensity: VisualDensity.compact);
                    }
                    return const Chip(
                      label: Text('Unassigned'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.redAccent,
                      labelStyle: TextStyle(color: Colors.white),
                    );
                  },
                  loading: () => const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (_, __) => const SizedBox(),
                ),
                onTap: () {
                  // TODO: Teacher Detail Screen
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildClassesList(ThemeData theme) {
    final classesAsync = ref.watch(classesBySchoolProvider(widget.schoolId));
    final teachersAsync = ref.watch(teachersBySchoolProvider(widget.schoolId));

    return classesAsync.when(
      data: (classes) {
        if (classes.isEmpty) {
          return const Center(child: Text('No classes found.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80, top: 8),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final cls = classes[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(cls.className, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: teachersAsync.when(
                  data: (teachers) {
                    final assignedTeacher = teachers.where((t) => t.uid == cls.teacherUid).firstOrNull;
                    if (assignedTeacher != null) {
                      return Text('Teacher: ${assignedTeacher.displayName}');
                    }
                    return const Text('No teacher assigned', style: TextStyle(color: Colors.red));
                  },
                  loading: () => const Text('Loading teacher...'),
                  error: (_, __) => const Text('Error'),
                ),
                trailing: CircleAvatar(
                  radius: 16,
                  child: Text(cls.studentIds.length.toString()),
                ),
                onTap: () {
                  // TODO: Class Detail Screen
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}
