import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/super_admin_providers.dart';

class SuperAdminDashboard extends ConsumerWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(platformStatsProvider);
    final schoolsAsync = ref.watch(allSchoolsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Platform Vitals', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            statsAsync.when(
              data: (stats) => Row(
                children: [
                  Expanded(child: _buildVitalCard(context, 'Total Schools', '${stats['totalSchools']}', Icons.business_rounded, Colors.blue)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildVitalCard(context, 'Active Schools', '${stats['activeSchools']}', Icons.check_circle_rounded, Colors.green)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildVitalCard(context, 'Inactive Schools', '${stats['inactiveSchools']}', Icons.pause_circle_rounded, Colors.orange)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildVitalCard(context, 'Total Students', '${stats['totalStudents']}', Icons.school_rounded, Colors.purple)),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading stats: $e'),
            ),
            const SizedBox(height: 48),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recent Schools Added', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      schoolsAsync.when(
                        data: (schools) {
                          // Sort by creation date descending (assuming it's a property, if not, fallback to alphabetical or ID for mock)
                          // Right now SchoolBranding doesn't have createdAt, so we just take the first 5.
                          final recent = schools.take(5).toList();
                          
                          if (recent.isEmpty) {
                            return const Card(child: Padding(padding: EdgeInsets.all(32), child: Text('No schools on platform yet.')));
                          }

                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHigh),
                              columns: const [
                                DataColumn(label: Text('School Name')),
                                DataColumn(label: Text('School Code')),
                                DataColumn(label: Text('Status')),
                              ],
                              rows: recent.map((school) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(school.schoolName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(Text(school.schoolId)),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: school.isActive ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          school.isActive ? 'Active' : 'Inactive',
                                          style: TextStyle(color: school.isActive ? Colors.green : Colors.orange, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (e, _) => Text('Error: $e'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('This Month', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.add_business_rounded, color: Colors.blue),
                                title: const Text('Schools Added'),
                                trailing: Text('1', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              ),
                              const Divider(),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.flash_on_rounded, color: Colors.green),
                                title: const Text('Schools Activated'),
                                trailing: Text('1', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
