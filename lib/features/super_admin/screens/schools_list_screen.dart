import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/firebase_constants.dart';

class SchoolsListScreen extends StatelessWidget {
  const SchoolsListScreen({super.key});

  Future<void> _toggleSchoolActive(String schoolId, bool currentStatus) async {
    await FirebaseFirestore.instance
        .collection(FirebaseConstants.kColSchools)
        .doc(schoolId)
        .update({'isActive': !currentStatus});
  }

  void _showEditDialog(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final nameController = TextEditingController(text: data['schoolName'] as String? ?? '');
    final colorController = TextEditingController(text: data['primaryColorHex'] as String? ?? '#4A90D9');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Edit School: ${doc.id}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'School Name'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter school name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: colorController,
                  decoration: const InputDecoration(labelText: 'Theme Color Hex (e.g. #4A90D9)'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter color code';
                    if (!RegExp(r'^#([A-Fa-f0-9]{6})$').hasMatch(val.trim())) return 'Invalid Hex format';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await FirebaseFirestore.instance
                    .collection(FirebaseConstants.kColSchools)
                    .doc(doc.id)
                    .update({
                  'schoolName': nameController.text.trim(),
                  'primaryColorHex': colorController.text.trim(),
                });
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Schools', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(FirebaseConstants.kColSchools).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No schools registered yet.'));
          }

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 250),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(theme.colorScheme.primaryContainer.withAlpha(50)),
                  columns: const [
                    DataColumn(label: Text('School Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('School Code', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Active Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Created Date', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final isActive = data['isActive'] as bool? ?? false;
                    final name = data['schoolName'] as String? ?? '';
                    
                    String createdStr = 'N/A';
                    if (data['createdAt'] != null) {
                      final createdTime = (data['createdAt'] as Timestamp).toDate();
                      createdStr = DateFormat.yMMMd().format(createdTime);
                    }

                    return DataRow(
                      onSelectChanged: (_) => _showEditDialog(context, doc),
                      cells: [
                        DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(doc.id)),
                        DataCell(
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(isActive ? 'Active' : 'Inactive'),
                            ],
                          ),
                        ),
                        DataCell(Text(createdStr)),
                        DataCell(
                          ElevatedButton(
                            onPressed: () => _toggleSchoolActive(doc.id, isActive),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isActive ? theme.colorScheme.errorContainer : theme.colorScheme.primaryContainer,
                              foregroundColor: isActive ? theme.colorScheme.onErrorContainer : theme.colorScheme.onPrimaryContainer,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              minimumSize: const Size(80, 32),
                            ),
                            child: Text(isActive ? 'Deactivate' : 'Activate'),
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
      ),
    );
  }
}
