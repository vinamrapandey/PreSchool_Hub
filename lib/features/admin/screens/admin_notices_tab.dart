import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/firebase_constants.dart';
import '../../../shared/models/notice.dart';
import '../../../shared/services/notice_service.dart';

class AdminNoticesTab extends ConsumerWidget {
  final String schoolId;

  const AdminNoticesTab({super.key, required this.schoolId});

  void _showNoticeForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => NoticeFormBottomSheet(schoolId: schoolId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: StreamBuilder<List<Notice>>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.kColNotices)
            .where('schoolId', isEqualTo: schoolId)
            .snapshots()
            .map((snapshot) {
              final list = snapshot.docs.map((doc) => Notice.fromFirestore(doc)).toList();
              list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
              return list;
            }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading notices: ${snapshot.error}'));
          }

          final notices = snapshot.data ?? [];

          if (notices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.campaign_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('No school notices found.', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('Announcements created will appear here for users.'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final notice = notices[index];
              final dateStr = DateFormat.yMMMd().format(notice.timestamp.toDate());

              return Card(
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: notice.isActive ? theme.colorScheme.secondaryContainer : theme.colorScheme.surfaceContainerHigh,
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: notice.isActive ? theme.colorScheme.onSecondaryContainer : Colors.grey,
                    ),
                  ),
                  title: Text(notice.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Posted on $dateStr • Targets: ${notice.targetRoles.join(", ")}'),
                  childrenPadding: const EdgeInsets.all(16.0),
                  expandedAlignment: Alignment.topLeft,
                  children: [
                    Text(notice.body, style: const TextStyle(height: 1.5)),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNoticeForm(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class NoticeFormBottomSheet extends ConsumerStatefulWidget {
  final String schoolId;

  const NoticeFormBottomSheet({super.key, required this.schoolId});

  @override
  ConsumerState<NoticeFormBottomSheet> createState() => _NoticeFormBottomSheetState();
}

class _NoticeFormBottomSheetState extends ConsumerState<NoticeFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  bool _targetParent = true;
  bool _targetTeacher = true;
  bool _targetManagement = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _saveNotice() async {
    if (!_formKey.currentState!.validate()) return;

    final targetRoles = <String>[];
    if (_targetParent) targetRoles.add('parent');
    if (_targetTeacher) targetRoles.add('teacher');
    if (_targetManagement) targetRoles.add('management');

    if (targetRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one target audience.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    final newNotice = Notice(
      noticeId: '', // auto-generated
      schoolId: widget.schoolId,
      title: title,
      body: body,
      targetRoles: targetRoles,
      createdByUid: currentUser.uid,
      timestamp: Timestamp.now(),
      isActive: true,
    );

    try {
      await ref.read(noticeServiceProvider).createNotice(newNotice);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notice posted successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting notice: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24.0,
        right: 24.0,
        top: 24.0,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Post New Notice',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Notice Title',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                enabled: !_isSaving,
              ),
              const SizedBox(height: 16),

              // Body Field
              TextFormField(
                controller: _bodyController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notice Message/Body',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter notice details';
                  }
                  return null;
                },
                enabled: !_isSaving,
              ),
              const SizedBox(height: 16),

              // Targets checkboxes
              Text('Target Audience', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Parents'),
                value: _targetParent,
                onChanged: _isSaving ? null : (val) => setState(() => _targetParent = val ?? false),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Teachers'),
                value: _targetTeacher,
                onChanged: _isSaving ? null : (val) => setState(() => _targetTeacher = val ?? false),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('School Management'),
                value: _targetManagement,
                onChanged: _isSaving ? null : (val) => setState(() => _targetManagement = val ?? false),
              ),
              const SizedBox(height: 24),

              // Action buttons
              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _saveNotice,
                          child: const Text('Post Notice'),
                        ),
                      ],
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
