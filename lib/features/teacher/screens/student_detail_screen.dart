import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/models/student.dart';

class StudentDetailScreen extends ConsumerStatefulWidget {
  final Student student;
  const StudentDetailScreen({super.key, required this.student});

  @override
  ConsumerState<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends ConsumerState<StudentDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form State
  String? _selectedMood;
  String _breakfastStatus = 'Skipped';
  String _lunchStatus = 'Skipped';
  String _snackStatus = 'Skipped';
  bool _hadNap = false;
  int _napDurationMin = 30;
  final _noteController = TextEditingController();

  final List<Map<String, String>> _moods = [
    {'emoji': '😄', 'label': 'Great'},
    {'emoji': '😊', 'label': 'Good'},
    {'emoji': '😐', 'label': 'Okay'},
    {'emoji': '😴', 'label': 'Tired'},
    {'emoji': '😢', 'label': 'Upset'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveReport() {
    // Logic to write to DailyReport collection
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Report saved for ${widget.student.name}!')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(widget.student.name),
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildProfileHeader(context),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: _buildReportForm(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedMood == null ? null : _saveReport,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: const Text('Save Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildHistorySection(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: widget.student.photoUrl != null && widget.student.photoUrl!.isNotEmpty
                ? CachedNetworkImageProvider(widget.student.photoUrl!)
                : null,
            child: widget.student.photoUrl == null || widget.student.photoUrl!.isEmpty
                ? Text(widget.student.name.substring(0, 1), style: const TextStyle(fontSize: 32))
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            widget.student.name,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Born: ${DateFormat('MMM d, yyyy').format(widget.student.dateOfBirth.toDate())}',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.call_rounded, size: 18),
                label: const Text('Call Parent'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildReportForm(BuildContext context) {
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
            Text("Today's Report", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Mood Selector
            const Text('Mood', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _moods.map((mood) {
                final isSelected = _selectedMood == mood['label'];
                return InkWell(
                  onTap: () => setState(() => _selectedMood = mood['label']),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primaryContainer : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? theme.colorScheme.primary : Colors.transparent),
                    ),
                    child: Column(
                      children: [
                        Text(mood['emoji']!, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text(mood['label']!, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const Divider(height: 32),

            // Meals
            const Text('Meals', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildMealRow('Breakfast', _breakfastStatus, (val) => setState(() => _breakfastStatus = val)),
            _buildMealRow('Lunch', _lunchStatus, (val) => setState(() => _lunchStatus = val)),
            _buildMealRow('Snack', _snackStatus, (val) => setState(() => _snackStatus = val)),
            
            const Divider(height: 32),

            // Nap
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nap', style: TextStyle(fontWeight: FontWeight.bold)),
                Switch(
                  value: _hadNap,
                  onChanged: (val) => setState(() => _hadNap = val),
                ),
              ],
            ),
            if (_hadNap)
              Row(
                children: [
                  const Text('Duration: '),
                  DropdownButton<int>(
                    value: _napDurationMin,
                    items: [15, 30, 45, 60, 90, 120].map((v) => DropdownMenuItem(value: v, child: Text('$v min'))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _napDurationMin = val);
                    },
                  ),
                ],
              ),
              
            const Divider(height: 32),

            // Note
            const Text('Teacher\'s Note (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add a personal note for parents...',
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealRow(String title, String value, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Ate well', label: Text('Ate well', style: TextStyle(fontSize: 10))),
              ButtonSegment(value: 'Partial', label: Text('Partial', style: TextStyle(fontSize: 10))),
              ButtonSegment(value: 'Skipped', label: Text('Skipped', style: TextStyle(fontSize: 10))),
            ],
            selected: {value},
            onSelectionChanged: (set) => onChanged(set.first),
            showSelectedIcon: false,
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Past Reports'),
            Tab(text: 'Attendance'),
          ],
        ),
        SizedBox(
          height: 300,
          child: TabBarView(
            controller: _tabController,
            children: [
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 5, // mock history
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Text('😄', style: TextStyle(fontSize: 24)),
                    title: Text('June ${12 - index}'),
                    subtitle: const Text('Ate well • 45m nap'),
                    trailing: const Icon(Icons.chevron_right),
                  );
                },
              ),
              const Center(child: Text('Attendance Calendar View')),
            ],
          ),
        ),
      ],
    );
  }
}
