import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/firebase_constants.dart';

class SuperAdminAddSchool extends StatefulWidget {
  const SuperAdminAddSchool({super.key});

  @override
  State<SuperAdminAddSchool> createState() => _SuperAdminAddSchoolState();
}

class _SuperAdminAddSchoolState extends State<SuperAdminAddSchool> {
  final _formKey = GlobalKey<FormState>();
  
  final _schoolNameController = TextEditingController();
  final _schoolCodeController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  
  String _primaryColorHex = '#4A90D9';
  bool _isLoading = false;
  bool _isCodeAvailable = true;
  String _codeCheckMessage = '';

  // Success state data
  bool _isSuccess = false;
  String _generatedPassword = '';

  @override
  void dispose() {
    _schoolNameController.dispose();
    _schoolCodeController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    // Auto-slugify for the school code
    final slug = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    _schoolCodeController.text = slug;
    _checkCodeAvailability(slug);
  }

  Future<void> _checkCodeAvailability(String code) async {
    if (code.isEmpty) {
      setState(() {
        _isCodeAvailable = false;
        _codeCheckMessage = 'School code cannot be empty.';
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection(FirebaseConstants.kColSchools).doc(code).get();
      if (mounted) {
        setState(() {
          _isCodeAvailable = !doc.exists;
          _codeCheckMessage = _isCodeAvailable ? '✅ $code is available' : '❌ $code is already taken';
        });
      }
    } catch (e) {
      // Handle error gracefully
    }
  }

  Future<void> _createSchool() async {
    if (!_formKey.currentState!.validate() || !_isCodeAvailable) return;

    setState(() {
      _isLoading = true;
    });

    final schoolName = _schoolNameController.text.trim();
    final schoolCode = _schoolCodeController.text.trim();
    final adminName = _adminNameController.text.trim();
    final adminEmail = _adminEmailController.text.trim();
    final tempPassword = 'temp${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'; // Generates something like temp12345

    try {
      // 1. Create School Document
      await FirebaseFirestore.instance.collection(FirebaseConstants.kColSchools).doc(schoolCode).set({
        'schoolId': schoolCode,
        'schoolName': schoolName,
        'logoUrl': '', // Logo upload skipped for MVP simplicity
        'primaryColorHex': _primaryColorHex,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Secondary App workaround for creating Admin Account without logging Super Admin out
      FirebaseApp secondaryApp;
      try {
        secondaryApp = Firebase.app('SecondaryApp');
      } catch (e) {
        // Initialize if it doesn't exist
        secondaryApp = await Firebase.initializeApp(
          name: 'SecondaryApp',
          options: Firebase.app().options,
        );
      }

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      
      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: tempPassword,
      );

      final uid = userCredential.user!.uid;

      // 3. Create Admin User Document in primary firestore
      await FirebaseFirestore.instance.collection(FirebaseConstants.kColUsers).doc(uid).set({
        'uid': uid,
        'email': adminEmail,
        'displayName': adminName,
        'role': 'admin', // Very important!
        'schoolId': schoolCode,
        'consentGiven': true, // Admins don't need parent consent
      });

      // Sign out the secondary app instance
      await secondaryAuth.signOut();

      // 4. Show success screen
      if (mounted) {
        setState(() {
          _isSuccess = true;
          _generatedPassword = tempPassword;
          _isLoading = false;
        });
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating school: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isSuccess) {
      return _buildSuccessScreen(theme);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New School', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('School Details', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _schoolNameController,
                            decoration: const InputDecoration(labelText: 'School Name', border: OutlineInputBorder()),
                            onChanged: _onNameChanged,
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _schoolCodeController,
                            decoration: const InputDecoration(labelText: 'School Code (Tenant ID)', border: OutlineInputBorder()),
                            onChanged: _checkCodeAvailability,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Required';
                              if (val.contains(' ')) return 'No spaces allowed';
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _codeCheckMessage,
                            style: TextStyle(color: _isCodeAvailable ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: _primaryColorHex,
                            decoration: const InputDecoration(labelText: 'Primary Color (Hex)', border: OutlineInputBorder()),
                            onChanged: (val) => _primaryColorHex = val,
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
                          TextFormField(
                            controller: _adminNameController,
                            decoration: const InputDecoration(labelText: 'Admin Full Name', border: OutlineInputBorder()),
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _adminEmailController,
                            decoration: const InputDecoration(labelText: 'Admin Email', border: OutlineInputBorder()),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Required';
                              if (!val.contains('@')) return 'Invalid email';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createSchool,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Create School & Admin Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen(ThemeData theme) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(48.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
                const SizedBox(height: 24),
                Text('School Created Successfully!', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text('Share these credentials with the school administrator.', style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
                const SizedBox(height: 32),
                
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildCredentialRow('School Code:', _schoolCodeController.text),
                      const Divider(height: 32),
                      _buildCredentialRow('Admin Email:', _adminEmailController.text),
                      const Divider(height: 32),
                      _buildCredentialRow('Temp Password:', _generatedPassword),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard (Mock)')));
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy Credentials'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isSuccess = false;
                          _schoolNameController.clear();
                          _schoolCodeController.clear();
                          _adminNameController.clear();
                          _adminEmailController.clear();
                          _primaryColorHex = '#4A90D9';
                        });
                      },
                      child: const Text('Add Another'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
      ],
    );
  }
}
