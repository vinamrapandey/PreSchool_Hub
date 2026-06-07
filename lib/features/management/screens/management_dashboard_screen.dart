import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/firebase_constants.dart';
import '../../../core/providers/branding_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/models/activity_post.dart';
import '../../../shared/models/notice.dart';

/// FutureProvider that fetches the count metrics for the management overview.
final managementStatsProvider = FutureProvider.family.autoDispose<Map<String, dynamic>, String>((ref, schoolId) async {
  final firestore = FirebaseFirestore.instance;

  // 1. Total Students Count
  final studentsQuery = await firestore
      .collection(FirebaseConstants.kColStudents)
      .where('schoolId', isEqualTo: schoolId)
      .get();
  final totalStudents = studentsQuery.docs.length;

  // 2. Total Teachers Count
  final teachersQuery = await firestore
      .collection(FirebaseConstants.kColUsers)
      .where('schoolId', isEqualTo: schoolId)
      .where('role', isEqualTo: 'teacher')
      .get();
  final totalTeachers = teachersQuery.docs.length;

  // 3. Today's Attendance rate calculations
  final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final attendanceQuery = await firestore
      .collection(FirebaseConstants.kColAttendance)
      .where('schoolId', isEqualTo: schoolId)
      .where('date', isEqualTo: todayStr)
      .get();

  final presentCount = attendanceQuery.docs
      .where((doc) => doc.data()['status'] == 'present')
      .length;

  double attendanceRate = 0.0;
  if (totalStudents > 0 && attendanceQuery.docs.isNotEmpty) {
    attendanceRate = (presentCount / totalStudents) * 100;
  } else if (totalStudents > 0) {
    attendanceRate = 100.0; // Default when no records yet, or 0. Let's make it 100.0
  }

  return {
    'totalStudents': totalStudents,
    'totalTeachers': totalTeachers,
    'attendanceRate': attendanceRate,
  };
});

/// FutureProvider resolving the last 14 days daily attendance rates for fl_chart.
final attendanceTrendProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, String>((ref, schoolId) async {
  final firestore = FirebaseFirestore.instance;
  final List<Map<String, dynamic>> trendData = [];

  // Get total students
  final studentsQuery = await firestore
      .collection(FirebaseConstants.kColStudents)
      .where('schoolId', isEqualTo: schoolId)
      .get();
  final totalStudents = studentsQuery.docs.length;

  if (totalStudents == 0) {
    return List.generate(14, (i) {
      final date = DateTime.now().subtract(Duration(days: 13 - i));
      return {
        'date': DateFormat('dd MMM').format(date),
        'rate': 100.0,
      };
    });
  }

  // Get last 14 days range starting date
  final startDate = DateTime.now().subtract(const Duration(days: 13));
  final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);

  final attendanceQuery = await firestore
      .collection(FirebaseConstants.kColAttendance)
      .where('schoolId', isEqualTo: schoolId)
      .where('date', isGreaterThanOrEqualTo: startDateStr)
      .get();

  final docs = attendanceQuery.docs;

  for (int i = 0; i < 14; i++) {
    final date = DateTime.now().subtract(Duration(days: 13 - i));
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final dateLabel = DateFormat('dd MMM').format(date);

    final dailyDocs = docs.where((doc) => doc.data()['date'] == dateStr);
    final dailyPresent = dailyDocs.where((doc) => doc.data()['status'] == 'present').length;

    double dailyRate = 0.0;
    if (dailyDocs.isNotEmpty) {
      dailyRate = (dailyPresent / totalStudents) * 100;
    } else {
      dailyRate = 100.0; // Assume full attendance if no record exists (e.g. weekends/holidays)
    }

    trendData.add({
      'date': dateLabel,
      'rate': dailyRate,
    });
  }

  return trendData;
});

/// FutureProvider that retrieves recent activity feeds.
final recentActivitiesProvider = FutureProvider.family.autoDispose<List<ActivityPost>, String>((ref, schoolId) async {
  final firestore = FirebaseFirestore.instance;
  final query = await firestore
      .collection(FirebaseConstants.kColActivities)
      .where('schoolId', isEqualTo: schoolId)
      .orderBy('timestamp', descending: true)
      .limit(5)
      .get();

  return query.docs.map((doc) => ActivityPost.fromFirestore(doc)).toList();
});

/// FutureProvider that fetches active notices.
final activeNoticesProvider = FutureProvider.family.autoDispose<List<Notice>, String>((ref, schoolId) async {
  final firestore = FirebaseFirestore.instance;
  final query = await firestore
      .collection(FirebaseConstants.kColNotices)
      .where('schoolId', isEqualTo: schoolId)
      .where('isActive', isEqualTo: true)
      .get();

  final list = query.docs.map((doc) => Notice.fromFirestore(doc)).toList();
  list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return list;
});

class ManagementDashboardScreen extends ConsumerWidget {
  const ManagementDashboardScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      await FirebaseAuth.instance.signOut();
      ref.read(brandingProvider.notifier).clearBranding();
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
    final branding = ref.watch(brandingProvider);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Not logged in.')));
    }

    final userProfileAsync = ref.watch(appUserProvider(currentUser.uid));

    return userProfileAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('User profile not set up.')));
        }

        final schoolId = user.schoolId;

        // Watch metric providers
        final statsAsync = ref.watch(managementStatsProvider(schoolId));
        final trendAsync = ref.watch(attendanceTrendProvider(schoolId));
        final activitiesAsync = ref.watch(recentActivitiesProvider(schoolId));
        final noticesAsync = ref.watch(activeNoticesProvider(schoolId));

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                if (branding?.logoUrl.isNotEmpty ?? false)
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: branding!.logoUrl,
                      width: 34,
                      height: 34,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  const Icon(Icons.school_rounded, size: 28),
                const SizedBox(width: 12),
                Text(
                  branding?.schoolName ?? 'Preschool Management',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: () => _logout(context, ref),
                tooltip: 'Log Out',
              ),
            ],
            elevation: 0,
            backgroundColor: theme.colorScheme.surface,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(
                color: theme.colorScheme.outlineVariant.withAlpha(80),
                height: 1.0,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Summary Cards Section
                Text('Overview Metrics', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                statsAsync.when(
                  data: (stats) => Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          icon: Icons.child_care_rounded,
                          color: Colors.blue,
                          number: stats['totalStudents'].toString(),
                          label: 'Total Students',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          icon: Icons.badge_rounded,
                          color: Colors.purple,
                          number: stats['totalTeachers'].toString(),
                          label: 'Total Teachers',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          icon: Icons.done_outline_rounded,
                          color: Colors.green,
                          number: '${stats['attendanceRate'].toStringAsFixed(0)}%',
                          label: 'Attendance',
                        ),
                      ),
                    ],
                  ),
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (err, _) => Text('Error: $err'),
                ),
                const SizedBox(height: 32),

                // 2. Attendance Trend LineChart Section
                Text('Attendance Trend (Last 14 Days)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                trendAsync.when(
                  data: (trend) => Card(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 16, left: 16, right: 24),
                      child: SizedBox(
                        height: 220,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: FlTitlesData(
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 22,
                                  interval: 3, // Only show every 3rd day to avoid label overlap
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index >= 0 && index < trend.length) {
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Text(
                                          trend[index]['date'],
                                          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  interval: 20,
                                  getTitlesWidget: (value, meta) {
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      child: Text(
                                        '${value.toInt()}%',
                                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: 13,
                            minY: 0,
                            maxY: 100,
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(
                                  trend.length,
                                  (idx) => FlSpot(idx.toDouble(), trend[idx]['rate'].toDouble()),
                                ),
                                isCurved: true,
                                color: theme.colorScheme.primary,
                                barWidth: 3.5,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: theme.colorScheme.primary.withAlpha(40),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error loading chart: $err'),
                ),
                const SizedBox(height: 32),

                // 3. Recent Activity Feed Section
                Text('Recent Classroom Activities', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                activitiesAsync.when(
                  data: (activities) {
                    if (activities.isEmpty) {
                      return const Card(child: ListTile(title: Text('No classroom updates published yet.')));
                    }
                    return Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: activities.length,
                        separatorBuilder: (context, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final post = activities[index];
                          final formattedTime = DateFormat('dd MMM, hh:mm a').format(post.timestamp.toDate());

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.surfaceContainerHigh,
                              child: const Icon(Icons.class_rounded, size: 20),
                            ),
                            title: Text(
                              '${post.teacherName} (Class ID: ${post.classId})',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              post.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              formattedTime,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error: $err'),
                ),
                const SizedBox(height: 32),

                // 4. Active Notices Section
                Text('Active Notices', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                noticesAsync.when(
                  data: (notices) {
                    if (notices.isEmpty) {
                      return const Card(child: ListTile(title: Text('No active notices.')));
                    }
                    return Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: notices.length,
                        separatorBuilder: (context, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final notice = notices[index];
                          final dateStr = DateFormat.yMMMd().format(notice.timestamp.toDate());

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.secondaryContainer,
                              foregroundColor: theme.colorScheme.onSecondaryContainer,
                              child: const Icon(Icons.campaign_rounded, size: 20),
                            ),
                            title: Text(notice.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Posted on $dateStr • Targets: ${notice.targetRoles.join(", ")}'),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error: $err'),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error loading profile: $err'))),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String number,
    required String label,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(128)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 12),
            Text(
              number,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
