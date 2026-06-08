import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/notice.dart';
import '../../../shared/services/notice_service.dart';
import 'parent_dashboard_screen.dart';

class ParentNoticesTab extends ConsumerStatefulWidget {
  const ParentNoticesTab({super.key});

  @override
  ConsumerState<ParentNoticesTab> createState() => _ParentNoticesTabState();
}

class _ParentNoticesTabState extends ConsumerState<ParentNoticesTab> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final selectedChild = ref.watch(selectedChildProvider);
    final theme = Theme.of(context);

    if (selectedChild == null) {
      return const Center(child: Text('No child selected'));
    }

    final noticeService = ref.read(noticeServiceProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Notices', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<Notice>>(
              stream: noticeService.getNoticesForRole(selectedChild.schoolId, 'parent'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading notices: ${snapshot.error}'));
                }

                var allNotices = snapshot.data ?? [];

                // Apply filtering
                if (_selectedFilter == 'School-wide') {
                  allNotices = allNotices.where((n) => n.targetClassId == null).toList();
                } else if (_selectedFilter == 'My Class') {
                  allNotices = allNotices.where((n) => n.targetClassId == selectedChild.classId).toList();
                }

                if (allNotices.isEmpty) {
                  return _buildEmptyState(theme);
                }

                final pinnedNotices = allNotices.where((n) => n.isPinned).toList();
                final regularNotices = allNotices.where((n) => !n.isPinned).toList();

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    if (pinnedNotices.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Text('📌 Pinned Notices', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      ...pinnedNotices.map((n) => _buildNoticeCard(n, theme, isPinned: true)),
                      const SizedBox(height: 16),
                    ],
                    if (regularNotices.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Text('Recent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      ...regularNotices.map((n) => _buildNoticeCard(n, theme, isPinned: false)),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: ['All', 'School-wide', 'My Class'].map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilter = filter);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNoticeCard(Notice notice, ThemeData theme, {required bool isPinned}) {
    final formattedTime = DateFormat.yMMMd().format(notice.timestamp.toDate());
    final isSchoolWide = notice.targetClassId == null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 0,
      color: isPinned ? Colors.orange.withAlpha(20) : theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPinned ? BorderSide(color: Colors.orange.withAlpha(100)) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Open full notice modal or screen
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      notice.title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.circle, color: Colors.blue, size: 10), // Unread indicator mock
                ],
              ),
              const SizedBox(height: 8),
              Text(
                notice.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isSchoolWide ? '🏫 School-wide' : '🏷 My Class',
                      style: TextStyle(fontSize: 10, color: theme.colorScheme.onSecondaryContainer),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formattedTime,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 48, color: theme.colorScheme.primary.withAlpha(150)),
          const SizedBox(height: 16),
          const Text('No notices right now. Check back later.'),
        ],
      ),
    );
  }
}
