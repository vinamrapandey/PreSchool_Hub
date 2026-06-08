import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/branding_provider.dart';

class AdminSettingsScreen extends ConsumerWidget {
  final String schoolId;
  const AdminSettingsScreen({super.key, required this.schoolId});

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
          SnackBar(content: Text('Failed to logout: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final branding = ref.watch(brandingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // School Profile Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('School Profile', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: branding?.logoUrl.isNotEmpty == true ? NetworkImage(branding!.logoUrl) : null,
              child: branding?.logoUrl.isEmpty == true ? const Icon(Icons.school) : null,
            ),
            title: const Text('School Logo'),
            trailing: const Icon(Icons.upload_rounded),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ImagePicker integration pending')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.business_rounded),
            title: Text(branding?.schoolName ?? 'School Name'),
            subtitle: const Text('Only super admins can change this'),
          ),
          ListTile(
            leading: const Icon(Icons.color_lens_rounded),
            title: const Text('Theme Color'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Theme customization pending')));
            },
          ),
          const Divider(),

          // Leave Requests
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Leave Requests', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
          ),
          ListTile(
            leading: const Icon(Icons.sick_rounded),
            title: const Text('Manage Leave Requests'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave Requests pending')));
            },
          ),
          const Divider(),

          // Admin Account
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Admin Account', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle_rounded),
            title: Text(currentUser?.displayName ?? 'Admin Name'),
            subtitle: Text(currentUser?.email ?? 'admin@example.com'),
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text('Log Out', style: TextStyle(color: Colors.red)),
            onTap: () {
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
                        _logout(context, ref);
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
          const Divider(),

          // About
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About / Privacy Policy'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Privacy Policy pending')));
            },
          ),
        ],
      ),
    );
  }
}
