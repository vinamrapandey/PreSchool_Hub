import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/management_providers.dart';

class OverviewTab extends ConsumerWidget {
  final String schoolId;
  const OverviewTab({super.key, required this.schoolId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(managementOverviewStatsProvider(schoolId));
    final classesAsync = ref.watch(managementClassesStatusProvider(schoolId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            DateTime.now().toLocal().toString().substring(0, 10),
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),

          // School Vitals Row
          statsAsync.when(
            data: (stats) => Row(
              children: [
                Expanded(child: _buildVitalCard('Students', '${stats['totalStudents']}', '🎒', theme)),
                const SizedBox(width: 8),
                Expanded(child: _buildVitalCard('Teachers', '${stats['totalTeachers']}', '👩‍🏫', theme)),
                const SizedBox(width: 8),
                Expanded(child: _buildVitalCard('Classes', '${stats['totalClasses']}', '🏫', theme)),
              ],
            ),
            loading: () => const Center(child: LinearProgressIndicator()),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 24),

          // Today at a Glance
          Text('Today at a Glance', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          statsAsync.when(
            data: (stats) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Attendance', style: theme.textTheme.titleMedium),
                            Text(
                              '${(stats['attendanceRate'] as double).toStringAsFixed(1)}% present today',
                              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                            ),
                          ],
                        ),
                        // Trend arrow (mocked for visual)
                        const Icon(Icons.trending_up_rounded, color: Colors.green, size: 36),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMiniStat('Present', '${stats['presentCount']}', Colors.green, theme),
                        _buildMiniStat('Absent', '${stats['absentCount']}', Colors.red, theme),
                        _buildMiniStat('Not Marked', '${stats['notMarkedCount']}', Colors.grey, theme),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMiniStat('Posts Today', '${stats['postsToday']}', Colors.blue, theme),
                        _buildMiniStat('Photos Shared', '${stats['photosSharedToday']}', Colors.purple, theme),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 16),

          // Class Status List
          Text('Class Status', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          classesAsync.when(
            data: (classes) {
              if (classes.isEmpty) return const Text('No classes found.');
              return Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: classes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final cls = classes[index];
                    return ListTile(
                      title: Text(cls.className, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(cls.teacherUid.isEmpty ? 'No teacher assigned' : 'Teacher Assigned'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Pending', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Error loading class status'),
          ),
          const SizedBox(height: 24),

          // This Month Summary
          Text('This Month Summary', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          statsAsync.when(
            data: (stats) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Average Attendance'),
                      trailing: Text('${(stats['avgAttendanceThisMonth'] as double).toStringAsFixed(1)}%', style: theme.textTheme.titleMedium),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Total Activity Posts'),
                      trailing: Text('124', style: theme.textTheme.titleMedium), // Mocked for historical
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Total Notices Sent'),
                      trailing: Text('${stats['totalNoticesThisMonth']}', style: theme.textTheme.titleMedium),
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 24),

          // Passive Alerts
          Text('Alerts', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildAlert(Icons.warning_amber_rounded, 'Sunflower Class has no teacher assigned.', Colors.orange, theme),
          _buildAlert(Icons.trending_down_rounded, 'Daisies Class below 75% attendance 3 days in a row.', Colors.red, theme),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildVitalCard(String title, String value, String emoji, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          Text(title, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color, ThemeData theme) {
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildAlert(IconData icon, String message, Color color, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(color: color.withOpacity(0.9)))),
        ],
      ),
    );
  }
}
