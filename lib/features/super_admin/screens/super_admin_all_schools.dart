import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/firebase_constants.dart';
import '../../../shared/models/school_branding.dart';
import '../providers/super_admin_providers.dart';
import 'super_admin_school_detail.dart';

class SuperAdminAllSchools extends ConsumerStatefulWidget {
  const SuperAdminAllSchools({super.key});

  @override
  ConsumerState<SuperAdminAllSchools> createState() => _SuperAdminAllSchoolsState();
}

class _SuperAdminAllSchoolsState extends ConsumerState<SuperAdminAllSchools> {
  String _searchQuery = '';
  String _filter = 'All'; // All, Active, Inactive

  Future<void> _toggleSchoolStatus(SchoolBranding school, bool newStatus) async {
    try {
      await FirebaseFirestore.instance.collection(FirebaseConstants.kColSchools).doc(school.schoolId).update({
        'isActive': newStatus,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${school.schoolName} is now ${newStatus ? 'Active' : 'Inactive'}')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schoolsAsync = ref.watch(allSchoolsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Schools', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search and Filter Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by School Name or Code...',
                      prefixIcon: Icon(Icons.search_rounded),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 32),
                Wrap(
                  spacing: 8,
                  children: ['All', 'Active', 'Inactive'].map((filter) {
                    return FilterChip(
                      label: Text(filter),
                      selected: _filter == filter,
                      onSelected: (selected) {
                        if (selected) setState(() => _filter = filter);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Data Table
            Expanded(
              child: schoolsAsync.when(
                data: (schools) {
                  // Apply filters
                  var filtered = schools.where((s) {
                    if (_filter == 'Active' && !s.isActive) return false;
                    if (_filter == 'Inactive' && s.isActive) return false;
                    
                    if (_searchQuery.isNotEmpty) {
                      return s.schoolName.toLowerCase().contains(_searchQuery) || s.schoolId.toLowerCase().contains(_searchQuery);
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No schools found matching your criteria.'));
                  }

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: SingleChildScrollView(
                      child: SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHigh),
                          columns: const [
                            DataColumn(label: Text('School Name')),
                            DataColumn(label: Text('School Code')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: filtered.map((school) {
                            return DataRow(
                              cells: [
                                DataCell(Row(
                                  children: [
                                    if (school.logoUrl.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 12.0),
                                        child: CircleAvatar(backgroundImage: NetworkImage(school.logoUrl), radius: 16),
                                      )
                                    else
                                      Padding(
                                        padding: const EdgeInsets.only(right: 12.0),
                                        child: CircleAvatar(backgroundColor: theme.colorScheme.primaryContainer, radius: 16, child: Icon(Icons.school, size: 16, color: theme.colorScheme.primary)),
                                      ),
                                    Text(school.schoolName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                )),
                                DataCell(Text(school.schoolId)),
                                DataCell(
                                  Switch(
                                    value: school.isActive,
                                    onChanged: (val) => _toggleSchoolStatus(school, val),
                                    activeColor: Colors.green,
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.visibility_rounded, size: 18),
                                        label: const Text('View'),
                                        onPressed: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => SuperAdminSchoolDetail(schoolCode: school.schoolId)));
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading schools: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
