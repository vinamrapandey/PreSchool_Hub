import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'super_admin_dashboard.dart';
import 'super_admin_all_schools.dart';
import 'super_admin_add_school.dart';
import 'super_admin_profile.dart';

class SuperAdminShell extends ConsumerStatefulWidget {
  const SuperAdminShell({super.key});

  @override
  ConsumerState<SuperAdminShell> createState() => _SuperAdminShellState();
}

class _SuperAdminShellState extends ConsumerState<SuperAdminShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Designed for Web/Desktop
    return Scaffold(
      body: Row(
        children: [
          // Fixed Left Sidebar
          Container(
            width: 250,
            color: theme.colorScheme.surfaceContainer,
            child: Column(
              children: [
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.admin_panel_settings_rounded, size: 32, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'PreSchool Hub\nSuper Admin',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard'),
                _buildNavItem(1, Icons.business_rounded, 'All Schools'),
                _buildNavItem(2, Icons.add_business_rounded, 'Add School'),
                const Spacer(),
                _buildNavItem(3, Icons.account_circle_rounded, 'My Account'),
                const SizedBox(height: 32),
              ],
            ),
          ),
          
          // Vertical Divider
          Container(width: 1, color: theme.colorScheme.outlineVariant),
          
          // Content Area
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                SuperAdminDashboard(),
                SuperAdminAllSchools(),
                SuperAdminAddSchool(),
                SuperAdminProfile(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        color: isSelected ? theme.colorScheme.primaryContainer : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
