import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/branding_provider.dart';
import '../../../shared/models/student.dart';
import '../../../shared/services/student_service.dart';
import 'parent_activity_feed.dart';
import 'parent_attendance_tab.dart';
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
    ParentActivityFeed(),
    ParentAttendanceTab(),
    ParentNoticesTab(),
    ParentProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final branding = ref.watch(brandingProvider);
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
      appBar: AppBar(
        title: childrenAsync.when(
          data: (children) => _buildChildSelector(children, selectedChild),
          loading: () => const Text('Loading portal...'),
          error: (_, __) => const Text('Parent Portal'),
        ),
        actions: [
          // Dynamic School Logo in Header
          if (branding?.logoUrl.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: branding!.logoUrl,
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const Icon(Icons.school_rounded),
                ),
              ),
            )
          else
            const Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Icon(Icons.school_rounded),
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
            icon: Icon(Icons.feed_outlined),
            selectedIcon: Icon(Icons.feed_rounded),
            label: 'Activity Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Attendance',
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

  /// Builds the app bar child selector dropdown or static title depending on child count.
  Widget _buildChildSelector(List<Student> children, Student? selectedChild) {
    if (children.isEmpty) {
      return const Text('Parent Portal');
    }
    if (children.length == 1) {
      return Text(
        children.first.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
    }

    return DropdownButtonHideUnderline(
      child: DropdownButton<Student>(
        value: selectedChild ?? (children.isNotEmpty ? children.first : null),
        icon: const Icon(Icons.arrow_drop_down_rounded, size: 28),
        items: children.map((Student child) {
          return DropdownMenuItem<Student>(
            value: child,
            child: Text(
              child.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          );
        }).toList(),
        onChanged: (Student? newValue) {
          if (newValue != null) {
            ref.read(selectedChildProvider.notifier).state = newValue;
          }
        },
      ),
    );
  }
}
