import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/attendance_record.dart';
import '../../../shared/services/attendance_service.dart';
import 'parent_dashboard_screen.dart';

class ParentAttendanceTab extends ConsumerStatefulWidget {
  const ParentAttendanceTab({super.key});

  @override
  ConsumerState<ParentAttendanceTab> createState() => _ParentAttendanceTabState();
}

class _ParentAttendanceTabState extends ConsumerState<ParentAttendanceTab> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      // Don't navigate to future months
      final now = DateTime.now();
      if (_selectedMonth.year < now.year || 
          (_selectedMonth.year == now.year && _selectedMonth.month < now.month)) {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      }
    });
  }

  int _getDaysInMonth(DateTime date) {
    final firstDayNextMonth = DateTime(date.year, date.month + 1, 1);
    final firstDayThisMonth = DateTime(date.year, date.month, 1);
    return firstDayNextMonth.difference(firstDayThisMonth).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final selectedChild = ref.watch(selectedChildProvider);
    final theme = Theme.of(context);

    if (selectedChild == null) {
      return const Center(
        child: Text('No child selected'),
      );
    }

    final yearMonthStr = DateFormat('yyyy-MM').format(_selectedMonth);
    final attendanceService = ref.read(attendanceServiceProvider);

    return Column(
      children: [
        // Month Selector Header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: _previousMonth,
              ),
              Text(
                DateFormat('MMMM yyyy').format(_selectedMonth),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: _nextMonth,
              ),
            ],
          ),
        ),

        // Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(Colors.green.shade600, 'Present', theme),
              _buildLegendItem(Colors.orange.shade600, 'Late', theme),
              _buildLegendItem(Colors.red.shade600, 'Absent', theme),
              _buildLegendItem(theme.colorScheme.surfaceContainerHigh, 'No Info', theme),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Calendar Grid
        Expanded(
          child: StreamBuilder<List<AttendanceRecord>>(
            stream: attendanceService.getStudentMonthlyAttendance(
              selectedChild.studentId,
              yearMonthStr,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading attendance: ${snapshot.error}'),
                );
              }

              final records = snapshot.data ?? [];
              final recordsMap = {for (var r in records) r.date: r.status};

              return _buildCalendarGrid(recordsMap, theme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(Map<String, AttendanceStatus> recordsMap, ThemeData theme) {
    final daysCount = _getDaysInMonth(_selectedMonth);
    
    // Find weekday offset of 1st day of month (Monday=1, Sunday=7)
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final offset = firstDayOfMonth.weekday - 1; // Align to Monday as start index 0

    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
      ),
      itemCount: 7 + offset + daysCount, // weekday row + empty offset cells + days
      itemBuilder: (context, index) {
        // Weekday header row
        if (index < 7) {
          return Center(
            child: Text(
              weekdays[index],
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          );
        }

        final cellIndex = index - 7;

        // Empty spacer cells for offset alignment
        if (cellIndex < offset) {
          return const SizedBox.shrink();
        }

        // Calendar Day cells
        final dayNum = cellIndex - offset + 1;
        final dateStr = '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
        
        final status = recordsMap[dateStr];
        Color cellColor = theme.colorScheme.surfaceContainerHigh;
        Color textColor = theme.colorScheme.onSurface;

        if (status != null) {
          textColor = Colors.white;
          switch (status) {
            case AttendanceStatus.present:
              cellColor = Colors.green.shade600;
              break;
            case AttendanceStatus.absent:
              cellColor = Colors.red.shade600;
              break;
            case AttendanceStatus.late:
              cellColor = Colors.orange.shade600;
              break;
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: cellColor,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: status == null
                ? null
                : [
                    BoxShadow(
                      color: cellColor.withAlpha(80),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              dayNum.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        );
      },
    );
  }
}
