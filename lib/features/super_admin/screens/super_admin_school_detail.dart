import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/firebase_constants.dart';
import '../../../shared/models/school_branding.dart';

class SuperAdminSchoolDetail extends StatefulWidget {
  final String schoolCode;
  const SuperAdminSchoolDetail({super.key, required this.schoolCode});

  @override
  State<SuperAdminSchoolDetail> createState() => _SuperAdminSchoolDetailState();
}

class _SuperAdminSchoolDetailState extends State<SuperAdminSchoolDetail> {
  SchoolBranding? _school;
  bool _isLoading = true;
  int _studentsCount = 0;
  int _teachersCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSchoolDetails();
  }

  Future<void> _loadSchoolDetails() async {
    try {
      final doc = await FirebaseFirestore.instance.collection(FirebaseConstants.kColSchools).doc(widget.schoolCode).get();
      if (doc.exists) {
        _school = SchoolBranding.fromFirestore(doc);
      }

      final studentsQuery = await FirebaseFirestore.instance.collection(FirebaseConstants.kColStudents).where('schoolId', isEqualTo: widget.schoolCode).get();
      _studentsCount = studentsQuery.docs.length;

      final teachersQuery = await FirebaseFirestore.instance.collection(FirebaseConstants.kColUsers).where('schoolId', isEqualTo: widget.schoolCode).where('role', isEqualTo: 'teacher').get();
      _teachersCount = teachersQuery.docs.length;

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleStatus(bool val) async {
    if (_school == null) return;
    try {
      await FirebaseFirestore.instance.collection(FirebaseConstants.kColSchools).doc(widget.schoolCode).update({'isActive': val});
      setState(() => _school = _school!.copyWith(isActive: val));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('School Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _school == null
              ? const Center(child: Text('School not found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('General Information', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  children: [
                                    ListTile(
                                      title: const Text('School Name'),
                                      subtitle: Text(_school!.schoolName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                      trailing: IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () {}), // Mock edit
                                    ),
                                    const Divider(),
                                    ListTile(
                                      title: const Text('School Code (Tenant ID)'),
                                      subtitle: Text(_school!.schoolId, style: theme.textTheme.titleMedium?.copyWith(fontFamily: 'monospace')),
                                    ),
                                    const Divider(),
                                    SwitchListTile(
                                      title: const Text('Account Status'),
                                      subtitle: Text(_school!.isActive ? 'Active - Users can login' : 'Deactivated - Login blocked'),
                                      value: _school!.isActive,
                                      onChanged: _toggleStatus,
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            Text('Admin Account', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  children: [
                                    const ListTile(
                                      leading: Icon(Icons.admin_panel_settings_rounded),
                                      title: Text('Admin User'),
                                      subtitle: Text('admin@${'example.com'}'), // Mocked email for MVP
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent (Mock)')));
                                      },
                                      icon: const Icon(Icons.lock_reset_rounded),
                                      label: const Text('Send Password Reset Email'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),

                      // Right Column
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Branding', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  children: [
                                    if (_school!.logoUrl.isNotEmpty)
                                      Image.network(_school!.logoUrl, height: 100)
                                    else
                                      Container(
                                        height: 100,
                                        width: 100,
                                        color: theme.colorScheme.surfaceContainerHigh,
                                        child: const Icon(Icons.image_not_supported_rounded, size: 40),
                                      ),
                                    const SizedBox(height: 16),
                                    OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.upload_rounded),
                                      label: const Text('Update Logo'),
                                    ),
                                    const Divider(height: 32),
                                    ListTile(
                                      title: const Text('Primary Color'),
                                      subtitle: Text(_school!.primaryColorHex),
                                      trailing: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Color(int.parse(_school!.primaryColorHex.replaceFirst('#', '0xFF'))),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.black12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            Text('Usage Metrics', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.school_rounded, color: Colors.blue),
                                      title: const Text('Total Students'),
                                      trailing: Text('$_studentsCount', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                    ),
                                    const Divider(height: 1),
                                    ListTile(
                                      leading: const Icon(Icons.badge_rounded, color: Colors.purple),
                                      title: const Text('Total Teachers'),
                                      trailing: Text('$_teachersCount', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
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
}
