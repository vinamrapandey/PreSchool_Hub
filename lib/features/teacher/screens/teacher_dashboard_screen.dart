import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/branding_provider.dart';
import '../../../shared/models/school_class.dart';
import '../../../shared/services/class_service.dart';
import 'teacher_class_tab.dart';
import 'teacher_attendance_tab.dart';
import 'teacher_post_tab.dart';

/// Provider resolving the class details taught by the logged-in teacher.
final teacherClassProvider = FutureProvider<SchoolClass?>((ref) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return null;
  return ref.read(classServiceProvider).getClassByTeacher(currentUser.uid);
});

class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends ConsumerState<TeacherDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    TeacherClassTab(),
    TeacherAttendanceTab(),
    TeacherPostTab(),
  ];

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      ref.read(brandingProvider.notifier).clearBranding();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to logout: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classAsync = ref.watch(teacherClassProvider);

    return Scaffold(
      appBar: AppBar(
        title: classAsync.when(
          data: (schoolClass) => Text(
            schoolClass != null ? 'Class: ${schoolClass.className}' : 'Teacher Portal',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          loading: () => const Text('Loading class info...'),
          error: (_, __) => const Text('Teacher Portal'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log Out',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.errorContainer,
                        foregroundColor: theme.colorScheme.onErrorContainer,
                      ),
                      child: const Text('Log Out'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: theme.colorScheme.outlineVariant.withAlpha(80),
            height: 1.0,
          ),
        ),
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'My Class',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check_rounded),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded),
            selectedIcon: Icon(Icons.add_circle_rounded),
            label: 'Post Update',
          ),
        ],
      ),
    );
  }
}
