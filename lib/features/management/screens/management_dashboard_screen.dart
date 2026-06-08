import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/branding_provider.dart';
import '../../../core/router/app_router.dart';
import 'tabs/overview_tab.dart';
import 'tabs/reports_tab.dart';
import 'tabs/notices_tab.dart';
import 'tabs/profile_tab.dart';

class ManagementDashboardScreen extends ConsumerStatefulWidget {
  const ManagementDashboardScreen({super.key});

  @override
  ConsumerState<ManagementDashboardScreen> createState() => _ManagementDashboardScreenState();
}

class _ManagementDashboardScreenState extends ConsumerState<ManagementDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final branding = ref.watch(brandingProvider);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Not logged in.')));
    }

    final userProfileAsync = ref.watch(appUserProvider(currentUser.uid));

    return userProfileAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('User profile not set up.')));
        }

        final schoolId = user.schoolId;

        final tabs = [
          OverviewTab(schoolId: schoolId),
          ReportsTab(schoolId: schoolId),
          NoticesTab(schoolId: schoolId),
          ProfileTab(user: user),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                if (branding?.logoUrl.isNotEmpty ?? false)
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: branding!.logoUrl,
                      width: 34,
                      height: 34,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  const Icon(Icons.school_rounded, size: 28),
                const SizedBox(width: 12),
                Text(
                  branding?.schoolName ?? 'School Management',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
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
              setState(() => _currentIndex = index);
            },
            destinations: const [
              NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Overview'),
              NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
              NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign_rounded), label: 'Notices'),
              NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error loading profile: $err'))),
    );
  }
}
