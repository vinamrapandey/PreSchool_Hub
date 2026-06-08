import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/activity_post.dart';
import '../../../../shared/models/daily_report.dart';

class DiaryTab extends ConsumerStatefulWidget {
  const DiaryTab({super.key});

  @override
  ConsumerState<DiaryTab> createState() => _DiaryTabState();
}

class _DiaryTabState extends ConsumerState<DiaryTab> {
  DateTime _selectedDate = DateTime.now();
  bool _isPhotoMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Diary', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isPhotoMode ? Icons.grid_view_rounded : Icons.photo_library_outlined),
            onPressed: () {
              setState(() {
                _isPhotoMode = !_isPhotoMode;
              });
            },
            tooltip: 'Toggle Photo Mode',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateStrip(context),
          const Divider(height: 1),
          Expanded(
            child: _isPhotoMode 
                ? _buildPhotoModeGrid(context)
                : _buildDiaryContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDateStrip(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final dates = List.generate(14, (i) => today.subtract(Duration(days: 13 - i)));

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = date.year == _selectedDate.year &&
                             date.month == _selectedDate.month &&
                             date.day == _selectedDate.day;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getWeekday(date.weekday),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getWeekday(int weekday) {
    switch (weekday) {
      case 1: return 'MON';
      case 2: return 'TUE';
      case 3: return 'WED';
      case 4: return 'THU';
      case 5: return 'FRI';
      case 6: return 'SAT';
      case 7: return 'SUN';
      default: return '';
    }
  }

  Widget _buildDiaryContent(BuildContext context) {
    // In a real app, we would fetch DailyReport and ActivityPosts for the selected date.
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDailyReportCard(context),
        const SizedBox(height: 24),
        const Text(
          'Activity Posts',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildActivityPostCard(context),
      ],
    );
  }

  Widget _buildDailyReportCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Daily Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Present', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildReportStat(context, 'Mood', '😊', 'Happy'),
                _buildReportStat(context, 'Meals', '🍱', 'Ate well'),
                _buildReportStat(context, 'Nap', '💤', '45 min'),
              ],
            ),
            const Divider(height: 24),
            Text(
              "Teacher's Note",
              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 4),
            const Text('Arjun had a great day today! He really enjoyed the painting activity and shared his toys with friends.'),
          ],
        ),
      ),
    );
  }

  Widget _buildReportStat(BuildContext context, String title, String emoji, String value) {
    return Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildActivityPostCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: const Icon(Icons.person, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Miss Sarah', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('10:30 AM', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('🎨 Art', style: TextStyle(fontSize: 12, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Finger painting session! We learned about mixing primary colors to create new ones.'),
            const SizedBox(height: 12),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Icon(Icons.image_rounded, size: 48, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoModeGrid(BuildContext context) {
    // A placeholder grid for photos
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(child: Icon(Icons.image, color: Colors.grey)),
        );
      },
    );
  }
}
