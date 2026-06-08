import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/branding_provider.dart';
import '../../../core/router/app_router.dart';
import 'parent_dashboard_screen.dart';

class ParentProfileTab extends ConsumerStatefulWidget {
  const ParentProfileTab({super.key});

  @override
  ConsumerState<ParentProfileTab> createState() => _ParentProfileTabState();
}

class _ParentProfileTabState extends ConsumerState<ParentProfileTab> {
  bool _activityUpdates = true;
  bool _noticeUpdates = true;
  bool _feeReminders = true;

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      await FirebaseAuth.instance.signOut();
      ref.read(brandingProvider.notifier).clearBranding();
      ref.read(selectedChildProvider.notifier).state = null;
      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to logout: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final selectedChild = ref.watch(selectedChildProvider);

    if (firebaseUser == null) {
      return const Center(child: Text('User details not found.'));
    }

    final appUserAsync = ref.watch(appUserProvider(firebaseUser.uid));

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedChild != null) _buildChildSection(theme, selectedChild),
            const SizedBox(height: 32),
            _buildParentSection(theme, appUserAsync),
            const SizedBox(height: 32),
            _buildAppSettings(theme),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildChildSection(ThemeData theme, var child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: child.photoUrl != null && child.photoUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(child.photoUrl!)
                  : null,
              child: child.photoUrl == null || child.photoUrl!.isEmpty
                  ? Icon(Icons.person, size: 40, color: theme.colorScheme.onPrimaryContainer)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(child.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Class ID: ${child.classId}', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 2),
                  const Text('Teacher: Miss Sarah', style: TextStyle(color: Colors.grey)), // Mock teacher
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Attendance Summary (This Month)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _AttendanceStat(label: 'Present', count: '18', color: Colors.green),
                    _AttendanceStat(label: 'Absent', count: '2', color: Colors.red),
                    _AttendanceStat(label: 'Late', count: '1', color: Colors.orange),
                  ],
                ),
                const Divider(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Request leave modal
                    },
                    icon: const Icon(Icons.edit_calendar_rounded),
                    label: const Text('Request Leave'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParentSection(ThemeData theme, AsyncValue appUserAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Parent Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                appUserAsync.when(
                  data: (user) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(user?.displayName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(user?.email ?? ''),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error loading parent details'),
                ),
                const Divider(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _logout(context, ref),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Log Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppSettings(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('App Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Activity Updates'),
                value: _activityUpdates,
                onChanged: (val) => setState(() => _activityUpdates = val),
              ),
              SwitchListTile(
                title: const Text('Notices'),
                value: _noticeUpdates,
                onChanged: (val) => setState(() => _noticeUpdates = val),
              ),
              SwitchListTile(
                title: const Text('Fee Reminders'),
                value: _feeReminders,
                onChanged: (val) => setState(() => _feeReminders = val),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  // Show DPDP info
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AttendanceStat extends StatelessWidget {
  final String label;
  final String count;
  final Color color;

  const _AttendanceStat({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
