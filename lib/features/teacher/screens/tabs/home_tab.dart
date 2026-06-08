import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../teacher_dashboard_screen.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final classAsync = ref.watch(teacherClassProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildGreetingHeader(context, user),
                  const SizedBox(height: 24),
                  
                  // Class Summary Card
                  classAsync.when(
                    data: (schoolClass) => schoolClass != null 
                        ? _buildClassSummaryCard(context, schoolClass.className, 22) // Mock student count
                        : const Text('No class assigned'),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Text('Failed to load class'),
                  ),

                  const SizedBox(height: 24),
                  _buildSectionTitle(context, "Today's Checklist"),
                  const SizedBox(height: 12),
                  _buildTodaysChecklist(context),

                  const SizedBox(height: 24),
                  _buildSectionTitle(context, "Quick Actions"),
                  const SizedBox(height: 12),
                  _buildQuickActionsRow(context),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, "Latest School Notice"),
                  const SizedBox(height: 12),
                  _buildLatestNoticeCard(context),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingHeader(BuildContext context, User? user) {
    final theme = Theme.of(context);
    final today = DateFormat('EEEE, MMMM d').format(DateTime.now());
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning!',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          today,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildClassSummaryCard(BuildContext context, String className, int studentCount) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      color: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimaryContainer.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.groups_rounded, size: 32, color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    className,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$studentCount students enrolled',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysChecklist(BuildContext context) {
    return Column(
      children: [
        _buildChecklistItem(
          context,
          icon: Icons.fact_check_rounded,
          title: 'Attendance',
          subtitle: 'Marked — 20 present, 2 absent', // Mock data
          isCompleted: true,
          onTap: () {
            // Jump to Attendance Tab
          },
        ),
        const SizedBox(height: 8),
        _buildChecklistItem(
          context,
          icon: Icons.assignment_rounded,
          title: 'Daily Reports',
          subtitle: '5 reports pending', // Mock data
          isCompleted: false,
          onTap: () {
            // Jump to My Class Tab
          },
        ),
        const SizedBox(height: 8),
        _buildChecklistItem(
          context,
          icon: Icons.photo_camera_back_rounded,
          title: 'Activity Post',
          subtitle: 'No post today yet', // Mock data
          isCompleted: false,
          onTap: () {
            // Jump to Updates Tab
          },
        ),
      ],
    );
  }

  Widget _buildChecklistItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted ? Colors.green.withAlpha(80) : theme.colorScheme.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isCompleted ? Colors.green : theme.colorScheme.onSurfaceVariant,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isCompleted ? Colors.green : theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(icon, color: theme.colorScheme.onSurfaceVariant.withAlpha(100)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildShortcutIcon(context, Icons.checklist_rtl_rounded, 'Mark\nAttendance', Colors.blue, () {}),
          _buildShortcutIcon(context, Icons.add_a_photo_rounded, 'Post\nUpdate', Colors.orange, () {}),
          _buildShortcutIcon(context, Icons.campaign_rounded, 'Class\nNotice', Colors.purple, () {}),
        ],
      ),
    );
  }

  Widget _buildShortcutIcon(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label, 
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLatestNoticeCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSecondaryContainer.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.campaign_rounded, color: theme.colorScheme.onSecondaryContainer),
        ),
        title: Text(
          'Staff Meeting at 3 PM', // Mock
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSecondaryContainer),
        ),
        subtitle: Text(
          'Please assemble in the main hall.',
          style: TextStyle(color: theme.colorScheme.onSecondaryContainer.withAlpha(180)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: theme.colorScheme.onSecondaryContainer),
        onTap: () {
          // Open Notice
          Scaffold.of(context).openEndDrawer();
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
