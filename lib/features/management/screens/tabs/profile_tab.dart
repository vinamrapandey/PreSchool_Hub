import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/branding_provider.dart';
import '../../../../shared/models/app_user.dart';

class ProfileTab extends ConsumerStatefulWidget {
  final AppUser user;
  const ProfileTab({super.key, required this.user});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  bool _dailySummary = true;
  bool _absenceAlerts = true;
  bool _newNotices = true;

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      ref.read(brandingProvider.notifier).clearBranding();
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to logout: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final branding = ref.watch(brandingProvider);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
          Text('Account Details', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.account_circle_rounded, size: 40),
                  title: Text(widget.user.displayName.isEmpty ? 'Management User' : widget.user.displayName),
                  subtitle: Text(widget.user.email),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.badge_rounded),
                  title: const Text('Role'),
                  trailing: const Text('Management / Director', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.business_rounded),
                  title: Text(branding?.schoolName ?? 'School Name'),
                  subtitle: Text('School Code: ${widget.user.schoolId}'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Notification Preferences
          Text('Notification Preferences', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Daily Attendance Summary'),
                  subtitle: const Text('Morning push notification with yesterday\'s attendance %'),
                  value: _dailySummary,
                  onChanged: (val) => setState(() => _dailySummary = val),
                  secondary: const Icon(Icons.summarize_rounded),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Absence Alerts'),
                  subtitle: const Text('Notify if attendance drops below 75%'),
                  value: _absenceAlerts,
                  onChanged: (val) => setState(() => _absenceAlerts = val),
                  secondary: const Icon(Icons.warning_rounded),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('New Notices'),
                  subtitle: const Text('Notify when admin sends a school-wide notice'),
                  value: _newNotices,
                  onChanged: (val) => setState(() => _newNotices = val),
                  secondary: const Icon(Icons.campaign_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Logout
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.errorContainer,
              foregroundColor: theme.colorScheme.onErrorContainer,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
