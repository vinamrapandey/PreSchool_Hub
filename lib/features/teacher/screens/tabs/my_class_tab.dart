import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/student.dart';
import '../student_detail_screen.dart';
import '../teacher_dashboard_screen.dart';
import 'attendance_tab.dart'; // To access teacherClassStudentsProvider

class MyClassTab extends ConsumerStatefulWidget {
  const MyClassTab({super.key});

  @override
  ConsumerState<MyClassTab> createState() => _MyClassTabState();
}

class _MyClassTabState extends ConsumerState<MyClassTab> {
  bool _isGridView = true;
  bool _filterPendingReports = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classAsync = ref.watch(teacherClassProvider);
    final studentsAsync = ref.watch(teacherClassStudentsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildHeader(context, classAsync.value?.className, studentsAsync.value?.length),
                  const SizedBox(height: 16),
                  _buildControls(context),
                ],
              ),
            ),
          ),
          studentsAsync.when(
            data: (students) {
              if (students.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('No students found.')),
                );
              }

              // Apply mock filter logic if _filterPendingReports is true
              // In reality, this needs to check against DailyReports fetched for today
              var displayStudents = students;
              if (_filterPendingReports) {
                // Mock: just show half of them as pending for demo
                displayStudents = students.take(students.length ~/ 2).toList();
              }

              if (displayStudents.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('All reports completed for today! 🎉')),
                );
              }

              if (_isGridView) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildStudentGridCard(context, displayStudents[index]),
                      childCount: displayStudents.length,
                    ),
                  ),
                );
              } else {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildStudentListCard(context, displayStudents[index]),
                      ),
                      childCount: displayStudents.length,
                    ),
                  ),
                );
              }
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String? className, int? count) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          setState(() {
            _filterPendingReports = !_filterPendingReports;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      className ?? 'Loading...',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${count ?? 0} Students',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _filterPendingReports ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '17 / 22', // Mock
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _filterPendingReports ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Reports Done',
                      style: TextStyle(
                        fontSize: 10,
                        color: _filterPendingReports ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _filterPendingReports ? 'Pending Reports' : 'All Students',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.grid_view_rounded),
                color: _isGridView ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                onPressed: () => setState(() => _isGridView = true),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.view_list_rounded),
                color: !_isGridView ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                onPressed: () => setState(() => _isGridView = false),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToDetail(Student student) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentDetailScreen(student: student),
      ),
    );
  }

  Widget _buildStudentGridCard(BuildContext context, Student student) {
    final theme = Theme.of(context);
    // Mock statuses for UI demonstration
    final isPresent = student.hashCode % 2 == 0;
    final reportDone = student.hashCode % 3 == 0;

    return Card(
      elevation: 1,
      color: theme.colorScheme.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToDetail(student),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: student.photoUrl != null && student.photoUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(student.photoUrl!)
                      : null,
                  child: student.photoUrl == null || student.photoUrl!.isEmpty
                      ? Text(student.name.substring(0, 1), style: const TextStyle(fontSize: 24))
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.circle,
                    size: 16,
                    color: isPresent ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                student.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  reportDone ? Icons.assignment_turned_in_rounded : Icons.assignment_late_rounded,
                  size: 16,
                  color: reportDone ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  reportDone ? 'Reported' : 'Pending',
                  style: TextStyle(
                    fontSize: 12,
                    color: reportDone ? Colors.blue : Colors.grey,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStudentListCard(BuildContext context, Student student) {
    final theme = Theme.of(context);
    final isPresent = student.hashCode % 2 == 0;
    final reportDone = student.hashCode % 3 == 0;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => _navigateToDetail(student),
        leading: Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: student.photoUrl != null && student.photoUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(student.photoUrl!)
                  : null,
              child: student.photoUrl == null || student.photoUrl!.isEmpty
                  ? Text(student.name.substring(0, 1))
                  : null,
            ),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.circle,
                size: 12,
                color: isPresent ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Icon(
          reportDone ? Icons.assignment_turned_in_rounded : Icons.assignment_late_rounded,
          color: reportDone ? Colors.blue : Colors.grey,
        ),
      ),
    );
  }
}
