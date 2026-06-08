import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/branding_provider.dart';
import '../../../../shared/models/student.dart';
import '../../../../shared/services/user_service.dart';
import '../parent_dashboard_screen.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final selectedChild = ref.watch(selectedChildProvider);
    final childrenAsync = ref.watch(parentChildrenProvider);
    final branding = ref.watch(brandingProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Row(
              children: [
                if (branding?.logoUrl.isNotEmpty ?? false) ...[
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: branding!.logoUrl,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(Icons.school_rounded),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                const Text('Parent Portal', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildGreetingHeader(context, ref, user),
                  const SizedBox(height: 24),
                  
                  if (childrenAsync.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (childrenAsync.hasError)
                    Text('Error loading children: ${childrenAsync.error}')
                  else if (childrenAsync.value != null && childrenAsync.value!.isNotEmpty)
                    _buildChildSwipeableCards(context, childrenAsync.value!, selectedChild, ref)
                  else
                    const Text('No children registered yet.'),

                  const SizedBox(height: 24),
                  _buildSectionTitle(context, "Today's Snapshot"),
                  const SizedBox(height: 12),
                  _buildTodaysSnapshotCard(context),

                  const SizedBox(height: 24),
                  _buildSectionTitle(context, "Upcoming"),
                  const SizedBox(height: 12),
                  _buildUpcomingCard(context),

                  const SizedBox(height: 24),
                  _buildSectionTitle(context, "Quick Shortcuts"),
                  const SizedBox(height: 12),
                  _buildQuickShortcutsRow(context),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingHeader(BuildContext context, WidgetRef ref, User? user) {
    final theme = Theme.of(context);
    
    // FutureBuilder or Provider to get parent name could go here
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning!',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Here is what is happening today.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildChildSwipeableCards(
    BuildContext context, 
    List<Student> children, 
    Student? selectedChild,
    WidgetRef ref,
  ) {
    return SizedBox(
      height: 140,
      child: PageView.builder(
        itemCount: children.length,
        controller: PageController(viewportFraction: 0.95),
        onPageChanged: (index) {
          ref.read(selectedChildProvider.notifier).state = children[index];
        },
        itemBuilder: (context, index) {
          final child = children[index];
          final isSelected = child.studentId == selectedChild?.studentId;
          return _buildChildBannerCard(context, child, isSelected);
        },
      ),
    );
  }

  Widget _buildChildBannerCard(BuildContext context, Student child, bool isSelected) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(right: 8),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: theme.colorScheme.primary.withAlpha(50),
              backgroundImage: child.photoUrl != null && child.photoUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(child.photoUrl!)
                  : null,
              child: child.photoUrl == null || child.photoUrl!.isEmpty
                  ? Icon(Icons.person_rounded, size: 36, color: theme.colorScheme.primary)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    child.name,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.meeting_room_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        'Class loading...', // Fetch class name later
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 10, color: Colors.green),
                        SizedBox(width: 4),
                        Text('Present Today', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
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

  Widget _buildTodaysSnapshotCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSnapshotItem(context, '😊', 'Happy'),
                _buildSnapshotItem(context, '🍱', 'Ate well'),
                _buildSnapshotItem(context, '💤', '45 min'),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('No photos yet today', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnapshotItem(BuildContext context, String emoji, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildUpcomingCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSecondaryContainer.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.event_rounded, color: theme.colorScheme.onSecondaryContainer),
        ),
        title: Text(
          'Annual Sports Day',
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSecondaryContainer),
        ),
        subtitle: Text(
          'Tomorrow • 9:00 AM',
          style: TextStyle(color: theme.colorScheme.onSecondaryContainer.withAlpha(180)),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: theme.colorScheme.onSecondaryContainer),
      ),
    );
  }

  Widget _buildQuickShortcutsRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildShortcutIcon(context, Icons.edit_calendar_rounded, 'Request Leave', Colors.blue),
          _buildShortcutIcon(context, Icons.payments_rounded, 'Fee Status', Colors.green),
          _buildShortcutIcon(context, Icons.photo_library_rounded, 'Gallery', Colors.purple),
          _buildShortcutIcon(context, Icons.call_rounded, 'Contact', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildShortcutIcon(BuildContext context, IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
