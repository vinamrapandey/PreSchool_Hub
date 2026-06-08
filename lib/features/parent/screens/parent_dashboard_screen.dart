import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/student.dart';
import '../../../shared/services/student_service.dart';
import 'tabs/home_tab.dart';
import 'tabs/diary_tab.dart';
import 'parent_notices_tab.dart';
import 'parent_profile_tab.dart';

/// Provider containing the list of children associated with the logged-in parent.
final parentChildrenProvider = StreamProvider<List<Student>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();
  return ref.read(studentServiceProvider).getStudentsByParentUid(user.uid);
});

/// StateProvider tracking the active child selected in the parent portal.
final selectedChildProvider = StateProvider<Student?>((ref) => null);

class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  ConsumerState<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends ConsumerState<ParentDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    HomeTab(),
    DiaryTab(),
    ParentNoticesTab(),
    ParentProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(parentChildrenProvider);
    final selectedChild = ref.watch(selectedChildProvider);

    // Auto-select first child if none is currently selected
    ref.listen<AsyncValue<List<Student>>>(parentChildrenProvider, (prev, next) {
      next.whenData((children) {
        if (children.isNotEmpty && ref.read(selectedChildProvider) == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedChildProvider.notifier).state = children.first;
          });
        }
      });
    });

    return Scaffold(
      body: SafeArea(child: _tabs[_currentIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories_rounded),
            label: 'Diary',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign_rounded),
            label: 'Notices',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
