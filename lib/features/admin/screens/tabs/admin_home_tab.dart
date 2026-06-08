import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/services/class_service.dart';
import '../../../../shared/services/notice_service.dart';
import '../../providers/admin_providers.dart';
import '../full_reports_screen.dart';
import '../compose_notice_screen.dart';

class AdminHomeTab extends ConsumerStatefulWidget {
  final String schoolId;
  const AdminHomeTab({super.key, required this.schoolId});

  @override
  ConsumerState<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends ConsumerState<AdminHomeTab> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classesAsync = ref.watch(classesBySchoolProvider(widget.schoolId));
    final noticesAsync = ref.watch(noticesBySchoolProvider(widget.schoolId));

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Greeting Header
            Text(
              'Good morning, Admin!',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              DateTime.now().toLocal().toString().substring(0, 10),
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            // Attendance Snapshot
            Text('School Attendance Snapshot', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard('Present', '0', Colors.green, theme)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('Absent', '0', Colors.red, theme)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('Not Marked', 'All', Colors.grey, theme)),
              ],
            ),
            const SizedBox(height: 24),

            // Class-wise Breakdown
            Text('Class-wise Breakdown', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            classesAsync.when(
              data: (classes) {
                if (classes.isEmpty) return const Text('No classes found.');
                return Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: classes.length,
                    separatorBuilder: (c, i) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final cls = classes[index];
                      return ListTile(
                        title: Text(cls.className),
                        subtitle: Text(cls.teacherUid.isEmpty ? 'No teacher' : 'Teacher Assigned'),
                        trailing: const Chip(
                          label: Text('Pending'),
                          backgroundColor: Colors.amberAccent,
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Error loading classes'),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Text('Quick Actions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(Icons.campaign_rounded, 'Send Notice', () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ComposeNoticeScreen(schoolId: widget.schoolId)));
                }, theme),
                _buildActionButton(Icons.bar_chart_rounded, 'View Reports', () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => FullReportsScreen(schoolId: widget.schoolId)));
                }, theme),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Notices
            Text('Recent Notices', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            noticesAsync.when(
              data: (notices) {
                final activeNotices = notices.where((n) => n.isActive).toList();
                activeNotices.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                final recent = activeNotices.take(2).toList();
                if (recent.isEmpty) return const Text('No recent notices.');
                return Column(
                  children: recent.map((n) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.campaign_rounded),
                      title: Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(n.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  )).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Error loading notices'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: theme.textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, ThemeData theme) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 8),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
