import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/notice.dart';
import '../teacher_dashboard_screen.dart';

class TeacherNoticesPanel extends ConsumerStatefulWidget {
  const TeacherNoticesPanel({super.key});

  @override
  ConsumerState<TeacherNoticesPanel> createState() => _TeacherNoticesPanelState();
}

class _TeacherNoticesPanelState extends ConsumerState<TeacherNoticesPanel> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isComposing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _sendNotice() {
    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) return;

    // Logic to save Notice to Firestore and send push notifications
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notice sent to all parents in your class!')),
    );

    _titleController.clear();
    _bodyController.clear();
    setState(() {
      _isComposing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classAsync = ref.watch(teacherClassProvider);

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      width: MediaQuery.of(context).size.width * 0.85,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  if (_isComposing)
                    SliverToBoxAdapter(child: _buildComposer(context, classAsync.value?.className))
                  else
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() => _isComposing = true),
                          icon: const Icon(Icons.add_alert_rounded),
                          label: const Text('Send Class Notice'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text('Received Notices', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildNoticeCard(context, index);
                      },
                      childCount: 4, // Mock
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_rounded, size: 28),
          const SizedBox(width: 12),
          const Text(
            'Notices',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer(BuildContext context, String? className) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('New Notice', style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _isComposing = false),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Notice Title',
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Notice Details...',
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.groups_rounded, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  'To: All parents of ${className ?? 'your class'}',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _sendNotice,
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Send Notice'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeCard(BuildContext context, int index) {
    final theme = Theme.of(context);
    final isUnread = index == 0;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Icon(Icons.campaign_rounded, color: theme.colorScheme.onSecondaryContainer),
            ),
            if (isUnread)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.surface, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          index == 0 ? 'Staff Meeting at 3 PM' : 'Tomorrow is a holiday',
          style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.normal),
        ),
        subtitle: const Text('10:00 AM • Admin'),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 72, right: 16, bottom: 16),
            child: Text(
              'Please assemble in the main hall. We will discuss the upcoming annual sports day preparations and class duty assignments.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
