import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/notice.dart';
import '../../../../shared/services/notice_service.dart';
import '../../providers/admin_providers.dart';
import '../compose_notice_screen.dart';

class AdminNoticesTab extends ConsumerStatefulWidget {
  final String schoolId;
  const AdminNoticesTab({super.key, required this.schoolId});

  @override
  ConsumerState<AdminNoticesTab> createState() => _AdminNoticesTabState();
}

class _AdminNoticesTabState extends ConsumerState<AdminNoticesTab> {
  String _selectedFilter = 'All'; // All, Pinned, School-wide, Class-specific, Drafts

  Future<void> _togglePin(Notice notice) async {
    try {
      await FirebaseFirestore.instance.collection('notices').doc(notice.noticeId).update({
        'isPinned': !notice.isPinned,
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteNotice(Notice notice) async {
    try {
      await FirebaseFirestore.instance.collection('notices').doc(notice.noticeId).delete();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final noticesAsync = ref.watch(noticesBySchoolProvider(widget.schoolId));
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: ['All', 'Pinned', 'School-wide', 'Class-specific', 'Drafts'].map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedFilter = filter);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          
          // List
          Expanded(
            child: noticesAsync.when(
              data: (notices) {
                // Filter logic
                List<Notice> filtered = notices.where((n) {
                  if (_selectedFilter == 'All') return n.isActive;
                  if (_selectedFilter == 'Pinned') return n.isActive && n.isPinned;
                  if (_selectedFilter == 'School-wide') return n.isActive && n.targetClassId == null;
                  if (_selectedFilter == 'Class-specific') return n.isActive && n.targetClassId != null;
                  if (_selectedFilter == 'Drafts') return !n.isActive;
                  return true;
                }).toList();

                // Sort: Pinned first, then chronological newest first
                filtered.sort((a, b) {
                  if (a.isPinned && !b.isPinned) return -1;
                  if (!a.isPinned && b.isPinned) return 1;
                  return b.timestamp.compareTo(a.timestamp);
                });

                if (filtered.isEmpty) {
                  return const Center(child: Text('No notices found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final notice = filtered[index];
                    return Dismissible(
                      key: Key(notice.noticeId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Notice'),
                            content: const Text('Are you sure you want to delete this notice?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) => _deleteNotice(notice),
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: InkWell(
                          onTap: () {
                            // Edit notice
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ComposeNoticeScreen(schoolId: widget.schoolId, existingNotice: notice),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (notice.isPinned) const Icon(Icons.push_pin_rounded, size: 16, color: Colors.orange),
                                    if (notice.isPinned) const SizedBox(width: 8),
                                    if (!notice.isActive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('DRAFT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    Expanded(
                                      child: Text(
                                        notice.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(notice.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined),
                                      onPressed: () => _togglePin(notice),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  notice.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      notice.targetClassId != null ? 'Target: Class' : 'Target: ${notice.targetRoles.join(', ')}',
                                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                                    ),
                                    Text(
                                      '${notice.timestamp.toDate().toLocal().toString().substring(0, 16)}',
                                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ComposeNoticeScreen(schoolId: widget.schoolId)),
          );
        },
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }
}
