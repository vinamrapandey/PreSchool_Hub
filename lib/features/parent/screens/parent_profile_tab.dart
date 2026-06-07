import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/branding_provider.dart';
import '../../../core/router/app_router.dart';
import 'parent_dashboard_screen.dart';

class ParentProfileTab extends ConsumerWidget {
  const ParentProfileTab({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      return const Center(child: Text('User details not found.'));
    }

    // Load AppUser details from ref
    final appUserAsync = ref.watch(appUserProvider(firebaseUser.uid));
    final childrenAsync = ref.watch(parentChildrenProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parent Profile Card
          appUserAsync.when(
            data: (user) {
              if (user == null) {
                return const Text('Parent information not found.');
              }
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        child: Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Role: Parent',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error loading profile: $err'),
          ),
          
          const SizedBox(height: 24),
          Text(
            'Linked Children',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Linked Children List
          childrenAsync.when(
            data: (children) {
              if (children.isEmpty) {
                return const Text(
                  'No children linked to this parent account. Contact admin.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: children.length,
                itemBuilder: (context, index) {
                  final child = children[index];
                  final isSelected = ref.watch(selectedChildProvider)?.studentId == child.studentId;

                  return Card(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer.withAlpha(50)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant.withAlpha(128),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: child.photoUrl != null && child.photoUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: child.photoUrl!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 48,
                                  height: 48,
                                  color: theme.colorScheme.surfaceContainerHigh,
                                  child: const CircularProgressIndicator(strokeWidth: 2),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 48,
                                  height: 48,
                                  color: theme.colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.face_rounded,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              )
                            : Container(
                                width: 48,
                                height: 48,
                                color: theme.colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.face_rounded,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                      ),
                      title: Text(
                        child.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Class ID: ${child.classId}'),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                          : OutlinedButton(
                              onPressed: () {
                                ref.read(selectedChildProvider.notifier).state = child;
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                minimumSize: const Size(60, 32),
                              ),
                              child: const Text('Select'),
                            ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error loading children: $err'),
          ),

          const SizedBox(height: 40),

          // Log Out Button
          OutlinedButton.icon(
            onPressed: () => _logout(context, ref),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log Out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
