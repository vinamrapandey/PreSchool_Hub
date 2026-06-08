import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../shared/models/notice.dart';

class ManagementComposeNoticeScreen extends StatefulWidget {
  final String schoolId;
  final Notice? existingNotice;

  const ManagementComposeNoticeScreen({super.key, required this.schoolId, this.existingNotice});

  @override
  State<ManagementComposeNoticeScreen> createState() => _ManagementComposeNoticeScreenState();
}

class _ManagementComposeNoticeScreenState extends State<ManagementComposeNoticeScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  
  bool _targetAll = true;
  bool _targetParents = false;
  bool _targetTeachers = false;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingNotice != null) {
      final n = widget.existingNotice!;
      _titleController.text = n.title;
      _bodyController.text = n.body;
      
      if (n.targetRoles.contains('all')) {
        _targetAll = true;
      } else {
        _targetAll = false;
        _targetParents = n.targetRoles.contains('parent');
        _targetTeachers = n.targetRoles.contains('teacher');
      }
    }
  }

  Future<void> _sendNotice() async {
    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and body are required')));
      return;
    }
    if (!_targetAll && !_targetParents && !_targetTeachers) {
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
      } else {
        if (_targetParents) roles.add('parent');
        if (_targetTeachers) roles.add('teacher');
      }

      final noticeData = {
        'schoolId': widget.schoolId,
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'targetRoles': roles,
        'targetClassId': null, // Management cannot target specific classes
        'isPinned': widget.existingNotice?.isPinned ?? false,
        'isActive': true, // Always active immediately
        'createdByUid': userUid,
        'timestamp': widget.existingNotice?.timestamp ?? Timestamp.now(),
      };

      await FirebaseFirestore.instance.collection('notices').doc(noticeId).set(noticeData, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notice sent successfully')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingNotice != null ? 'Edit Notice' : 'Compose Notice'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Notice Title', border: OutlineInputBorder()),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(labelText: 'Notice Body', border: OutlineInputBorder(), alignLabelWithHint: true),
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
                      }
                    });
                  },
                ),
                FilterChip(
                  label: const Text('All Parents'),
                  selected: !_targetAll && _targetParents,
                  onSelected: (val) {
                    setState(() {
                      _targetAll = false;
                      _targetParents = val;
                    });
                  },
                ),
                FilterChip(
                  label: const Text('All Teachers'),
                  selected: !_targetAll && _targetTeachers,
                  onSelected: (val) {
                    setState(() {
                      _targetAll = false;
                      _targetTeachers = val;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Note: Class-specific notices can only be sent by School Administrators.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            
            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _sendNotice,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Send Notice Now'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
          ],
        ),
      ),
    );
  }
}
