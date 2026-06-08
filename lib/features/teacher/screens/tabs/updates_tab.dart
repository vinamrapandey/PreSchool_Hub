import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/models/activity_post.dart';
import '../teacher_dashboard_screen.dart';

class UpdatesTab extends ConsumerStatefulWidget {
  const UpdatesTab({super.key});

  @override
  ConsumerState<UpdatesTab> createState() => _UpdatesTabState();
}

class _UpdatesTabState extends ConsumerState<UpdatesTab> {
  final _postController = TextEditingController();
  String _selectedActivityType = 'Learning';

  final List<String> _activityTypes = [
    'Art', 'Story', 'Outdoor', 'Music', 'Learning', 'Meal', 'Exercise', 'Play'
  ];

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  void _postUpdate() {
    if (_postController.text.trim().isEmpty) return;
    
    // Logic to post update
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Update posted successfully!')),
    );
    
    _postController.clear();
    setState(() {
      _selectedActivityType = 'Learning';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildComposeCard(context),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text("Today's Posts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: _buildPostCard(context),
                );
              },
              childCount: 2, // Mock today posts count
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Text("Past Posts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildPastPostSection(context, "Yesterday");
              },
              childCount: 3, // Mock past post groups
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildComposeCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _postController,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: "What's happening in class today?",
                border: InputBorder.none,
                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withAlpha(150)),
              ),
            ),
            const Divider(),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _activityTypes.map((type) {
                  final isSelected = _selectedActivityType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() => _selectedActivityType = type);
                      },
                      selectedColor: theme.colorScheme.primaryContainer,
                      checkmarkColor: theme.colorScheme.primary,
                      showCheckmark: false,
                      side: BorderSide(
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt_rounded),
                  color: theme.colorScheme.primary,
                  onPressed: () {},
                  tooltip: 'Take Photo',
                ),
                IconButton(
                  icon: const Icon(Icons.photo_library_rounded),
                  color: theme.colorScheme.primary,
                  onPressed: () {},
                  tooltip: 'Gallery',
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _postUpdate,
                  child: const Text('Post'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🎨 Art',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '10:30 AM',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('The children had a great time painting their favorite animals today!'),
            const SizedBox(height: 12),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Icon(Icons.photo_outlined, size: 48, color: Colors.grey)),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.delete_rounded, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPastPostSection(BuildContext context, String title) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: _buildPostCard(context),
          ),
        ],
      ),
    );
  }
}
