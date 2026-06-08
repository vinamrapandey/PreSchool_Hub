import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/notice.dart';
import '../../../../shared/services/class_service.dart';
import '../providers/admin_providers.dart';

class ComposeNoticeScreen extends ConsumerStatefulWidget {
  final String schoolId;
  final Notice? existingNotice;

  const ComposeNoticeScreen({super.key, required this.schoolId, this.existingNotice});

  @override
  ConsumerState<ComposeNoticeScreen> createState() => _ComposeNoticeScreenState();
}

class _ComposeNoticeScreenState extends ConsumerState<ComposeNoticeScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  
  bool _targetAll = true;
  bool _targetParents = false;
  bool _targetTeachers = false;
  String? _targetClassId;
  
  bool _isPinned = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingNotice != null) {
      final n = widget.existingNotice!;
      _titleController.text = n.title;
      _bodyController.text = n.body;
      _isPinned = n.isPinned;
      _targetClassId = n.targetClassId;
      
      if (_targetClassId != null) {
        _targetAll = false;
      } else {
        if (n.targetRoles.contains('all')) {
          _targetAll = true;
        } else {
          _targetAll = false;
          _targetParents = n.targetRoles.contains('parent');
          _targetTeachers = n.targetRoles.contains('teacher');
        }
      }
    }
  }

  Future<void> _saveNotice(bool isDraft) async {
    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and body are required')));
      return;
    }
    if (!_targetAll && !_targetParents && !_targetTeachers && _targetClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one target audience')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userUid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      final noticeId = widget.existingNotice?.noticeId ?? FirebaseFirestore.instance.collection('notices').doc().id;
      
      List<String> roles = [];
      if (_targetAll) {
        roles = ['all'];
      } else if (_targetClassId != null) {
        roles = ['parent', 'teacher']; // Target class implies those involved in the class
      } else {
        if (_targetParents) roles.add('parent');
        if (_targetTeachers) roles.add('teacher');
      }

      final noticeData = {
        'schoolId': widget.schoolId,
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'targetRoles': roles,
        'targetClassId': _targetAll ? null : _targetClassId,
        'isPinned': _isPinned,
        'isActive': !isDraft,
        'createdByUid': userUid,
        'timestamp': widget.existingNotice?.timestamp ?? Timestamp.now(),
      };

      await FirebaseFirestore.instance.collection('notices').doc(noticeId).set(noticeData, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isDraft ? 'Notice saved as draft' : 'Notice sent successfully')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesBySchoolProvider(widget.schoolId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingNotice != null ? 'Edit Notice' : 'Compose Notice'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => _saveNotice(true),
            child: const Text('Save Draft'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Notice Title',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Notice Body',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 8,
            ),
            const SizedBox(height: 24),
            
            Text('Target Audience', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Everyone'),
                  selected: _targetAll,
                  onSelected: (val) {
                    setState(() {
                      _targetAll = val;
                      if (val) {
                        _targetParents = false;
                        _targetTeachers = false;
                        _targetClassId = null;
                      }
                    });
                  },
                ),
                FilterChip(
                  label: const Text('All Parents'),
                  selected: !_targetAll && _targetParents && _targetClassId == null,
                  onSelected: (val) {
                    setState(() {
                      _targetAll = false;
                      _targetClassId = null;
                      _targetParents = val;
                    });
                  },
                ),
                FilterChip(
                  label: const Text('All Teachers'),
                  selected: !_targetAll && _targetTeachers && _targetClassId == null,
                  onSelected: (val) {
                    setState(() {
                      _targetAll = false;
                      _targetClassId = null;
                      _targetTeachers = val;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            classesAsync.when(
              data: (classes) => DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Or select a specific class'),
                value: _targetClassId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...classes.map((c) => DropdownMenuItem(value: c.classId, child: Text(c.className))),
                ],
                onChanged: (val) {
                  setState(() {
                    _targetClassId = val;
                    if (val != null) _targetAll = false;
                  });
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading classes'),
            ),
            
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Pin this notice'),
              subtitle: const Text('Pinned notices stay at the top of the list'),
              value: _isPinned,
              onChanged: (val) => setState(() => _isPinned = val),
              contentPadding: EdgeInsets.zero,
            ),
            
            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: () => _saveNotice(false),
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Send Notice Now'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
