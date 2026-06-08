import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/management_providers.dart';

class ReportsTab extends ConsumerWidget {
  final String schoolId;
  const ReportsTab({super.key, required this.schoolId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final trendAsync = ref.watch(managementAttendanceTrendProvider(schoolId));
    final classesAsync = ref.watch(managementClassesStatusProvider(schoolId));

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar: Date Range + Share
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: 'This Month',
                  items: ['This Week', 'This Month', 'Last Month'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {},
                  underline: const SizedBox(),
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating text report...')));
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Attendance Section
            Text('Attendance Report', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            trendAsync.when(
              data: (trend) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('School-wide Trend', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: true, drawVerticalLine: false),
                            titlesData: FlTitlesData(
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 22,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index >= 0 && index < trend.length) {
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Text(trend[index]['date'].toString().split(' ')[0], style: const TextStyle(fontSize: 10)),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: 6,
                            minY: 0,
                            maxY: 100,
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(trend.length, (idx) => FlSpot(idx.toDouble(), trend[idx]['rate'].toDouble())),
                                isCurved: true,
                                color: theme.colorScheme.primary,
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(show: true, color: theme.colorScheme.primary.withAlpha(50)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Error loading chart'),
            ),
            const SizedBox(height: 12),

            // Class comparison chart (Mocked Bar Chart)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Class Comparison', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 150,
                      child: BarChart(
                        BarChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: FlTitlesData(
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final names = ['Sun', 'Moon', 'Star', 'Sky'];
                                  if (value >= 0 && value < names.length) {
                                    return SideTitleWidget(axisSide: meta.axisSide, child: Text(names[value.toInt()], style: const TextStyle(fontSize: 10)));
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 92, color: Colors.green)]),
                            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 88, color: Colors.green)]),
                            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 76, color: Colors.orange)]),
                            BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 95, color: Colors.green)]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Chronic Absence
            Text('Chronic Absence Flags', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                title: const Text('John Doe (Moon Class)'),
                trailing: const Text('6 Days', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),

            // Teacher Activity
            Text('Teacher Activity Report', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildActivityRow('Ms. Sharma', 24, 18),
                    const Divider(),
                    _buildActivityRow('Mr. David', 12, 5),
                    const Divider(),
                    _buildActivityRow('Mrs. Lee', 30, 22),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow(String name, int posts, int photos) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
          Text('$posts Posts', style: const TextStyle(color: Colors.blue)),
          const SizedBox(width: 16),
          Text('$photos Photos', style: const TextStyle(color: Colors.purple)),
        ],
      ),
    );
  }
}
