import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/branding_provider.dart';
import '../../../core/router/app_router.dart';
import 'admin_settings_screen.dart';
import 'tabs/admin_home_tab.dart';
import 'tabs/admin_students_tab.dart';
import 'tabs/admin_staff_tab.dart';
import 'tabs/admin_notices_tab.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final branding = ref.watch(brandingProvider);

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Not logged in.')));
    }

    final adminUserAsync = ref.watch(appUserProvider(currentUser.uid));

    return adminUserAsync.when(
      data: (adminUser) {
        if (adminUser == null) {
          return const Scaffold(body: Center(child: Text('Profile not set up.')));
        }

        final String schoolId = adminUser.schoolId;

        final List<Widget> tabs = [
          AdminHomeTab(schoolId: schoolId),
          AdminStudentsTab(schoolId: schoolId),
          AdminStaffTab(schoolId: schoolId),
          AdminNoticesTab(schoolId: schoolId),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                if (branding != null && branding.logoUrl.isNotEmpty) ...[
                  CircleAvatar(
                    backgroundImage: NetworkImage(branding.logoUrl),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    radius: 16,
                  ),
                  const SizedBox(width: 12),
                ],
                const Text('Admin Portal', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_rounded),
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminSettingsScreen(schoolId: schoolId),
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
          body: tabs[_currentIndex],
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
                icon: Icon(Icons.child_care_outlined),
                selectedIcon: Icon(Icons.child_care_rounded),
                label: 'Students',
              ),
              NavigationDestination(
                icon: Icon(Icons.badge_outlined),
                selectedIcon: Icon(Icons.badge_rounded),
                label: 'Staff',
              ),
              NavigationDestination(
                icon: Icon(Icons.campaign_outlined),
                selectedIcon: Icon(Icons.campaign_rounded),
                label: 'Notices',
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error loading admin profile: $err'))),
    );
  }
}
