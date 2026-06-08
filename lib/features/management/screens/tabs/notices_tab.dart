import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/notice.dart';
import '../../providers/management_providers.dart';
import '../management_compose_notice_screen.dart';

class NoticesTab extends ConsumerStatefulWidget {
  final String schoolId;
  const NoticesTab({super.key, required this.schoolId});

  @override
  ConsumerState<NoticesTab> createState() => _NoticesTabState();
}

class _NoticesTabState extends ConsumerState<NoticesTab> {
  String _selectedFilter = 'All'; // All, Sent by Me, Sent by Admin

  Future<void> _deleteNotice(Notice notice) async {
    try {
      await FirebaseFirestore.instance.collection('notices').doc(notice.noticeId).delete();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final noticesAsync = ref.watch(managementNoticesProvider(widget.schoolId));
    final theme = Theme.of(context);
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      body: Column(
        children: [
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: ['All', 'Sent by Me', 'Sent by Admin'].map((filter) {
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
                  if (!n.isActive) return false; // Management only sees active notices by default unless they made drafts
                  if (_selectedFilter == 'All') return true;
                  if (_selectedFilter == 'Sent by Me') return n.createdByUid == currentUid;
                  if (_selectedFilter == 'Sent by Admin') return n.createdByUid != currentUid;
                  return true;
                }).toList();

                filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                if (filtered.isEmpty) {
                  return const Center(child: Text('No notices found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final notice = filtered[index];
                    final isMine = notice.createdByUid == currentUid;
                    
                    Widget cardContent = Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: InkWell(
                        onTap: isMine ? () {
                          // Edit own notice
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ManagementComposeNoticeScreen(schoolId: widget.schoolId, existingNotice: notice),
                            ),
                          );
                        } : null,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (notice.isPinned) const Icon(Icons.push_pin_rounded, size: 16, color: Colors.orange),
                                  if (notice.isPinned) const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      notice.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                notice.body,
                                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isMine ? 'Sent by: You' : 'Sent by: Admin',
                                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    notice.targetClassId != null ? 'Target: Class' : 'Target: ${notice.targetRoles.join(', ')}',
                                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );

                    if (isMine) {
                      return Dismissible(
                        key: Key(notice.noticeId),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
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
                        onDismissed: (_) => _deleteNotice(notice),
                        child: cardContent,
                      );
                    } else {
                      return cardContent;
                    }
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
            MaterialPageRoute(builder: (context) => ManagementComposeNoticeScreen(schoolId: widget.schoolId)),
          );
        },
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }
}
