import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/branding_provider.dart';
import 'add_school_screen.dart';
import 'schools_list_screen.dart';

class SuperAdminShell extends StatefulWidget {
  const SuperAdminShell({super.key});

  @override
  State<SuperAdminShell> createState() => _SuperAdminShellState();
}

class _SuperAdminShellState extends State<SuperAdminShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          // Permanent NavigationRail on the left (width 200)
          SizedBox(
            width: 200,
            child: NavigationRail(
              extended: true,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              backgroundColor: theme.colorScheme.surfaceContainerLow,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 12.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.colorScheme.primary,
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Super Admin',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Central Portal',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.business_rounded),
                  selectedIcon: Icon(Icons.business_rounded),
                  label: Text('Schools List'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.add_business_rounded),
                  selectedIcon: Icon(Icons.add_business_rounded),
                  label: Text('Add School'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.account_circle_rounded),
                  selectedIcon: Icon(Icons.account_circle_rounded),
                  label: Text('My Account'),
                ),
              ],
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Right side shows selected screen via IndexedStack
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                SchoolsListScreen(),
                AddSchoolScreen(),
                SuperAdminAccountTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SuperAdminAccountTab extends ConsumerWidget {
  const SuperAdminAccountTab({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      await FirebaseAuth.instance.signOut();
      ref.read(brandingProvider.notifier).clearBranding();
      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to logout: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'superadmin@preschoolhub.in';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Super Administrator',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'System Owner',
                        style: TextStyle(
                          color: theme.colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('Email Address'),
                      subtitle: Text(email),
                    ),
                    ListTile(
                      leading: const Icon(Icons.security_rounded),
                      title: const Text('Security Level'),
                      subtitle: const Text('Full Access (All Tenants)'),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => _logout(context, ref),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
