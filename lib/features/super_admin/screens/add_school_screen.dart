import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/firebase_constants.dart';

class AddSchoolScreen extends StatefulWidget {
  const AddSchoolScreen({super.key});

  @override
  State<AddSchoolScreen> createState() => _AddSchoolScreenState();
}

class _AddSchoolScreenState extends State<AddSchoolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _colorController = TextEditingController(value: '#4A90D9');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _colorController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final String name = _nameController.text.trim();
    final String code = _codeController.text.trim().toLowerCase().replaceAll(' ', '_');
    final String colorHex = _colorController.text.trim();
    final String adminEmail = _emailController.text.trim();
    final String adminPassword = _passwordController.text.trim();

    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Verify if school code (document ID) already exists
      final schoolDoc = await firestore
          .collection(FirebaseConstants.kColSchools)
          .doc(code)
          .get();

      if (schoolDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('School code already exists! Choose another unique code.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          _isSaving = false;
        });
        return;
      }

      // 2. Create the Admin user in Firebase Auth without logging out current Super Admin
      // Done using a temporary secondary FirebaseApp instance.
      final FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: 'TempAdminCreatorApp',
        options: Firebase.app().options,
      );

      final UserCredential userCreds = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(email: adminEmail, password: adminPassword);

      final String adminUid = userCreds.user!.uid;

      // Clean up secondary app instance references
      await secondaryApp.delete();

      // 3. Create the School document
      await firestore.collection(FirebaseConstants.kColSchools).doc(code).set({
        'schoolName': name,
        'logoUrl': '',
        'primaryColorHex': colorHex,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Create the Admin user document
      await firestore.collection(FirebaseConstants.kColUsers).doc(adminUid).set({
        'uid': adminUid,
        'email': adminEmail,
        'displayName': 'School Admin',
        'role': 'admin',
        'schoolId': code,
        'consentGiven': false,
      });

      // 5. Reset State on Success
      _nameController.clear();
      _codeController.clear();
      _colorController.text = '#4A90D9';
      _emailController.clear();
      _passwordController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('School and Admin Account registered successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add School Tenant', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('School Identity Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // School Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'School Name',
                      prefixIcon: Icon(Icons.school_rounded),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter school name' : null,
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 16),

                  // School Code
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'School Code (Unique Identifier)',
                      hintText: 'e.g. greenwood_preschool (letters, numbers, underscores)',
                      prefixIcon: Icon(Icons.vpn_key_rounded),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter unique school code';
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(val.trim())) {
                        return 'Only alphanumeric letters and underscores allowed';
                      }
                      return null;
                    },
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 16),

                  // Primary Color
                  TextFormField(
                    controller: _colorController,
                    decoration: const InputDecoration(
                      labelText: 'Primary Seed Color (Hex Code)',
                      hintText: 'e.g. #4A90D9',
                      prefixIcon: Icon(Icons.palette_rounded),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter color code';
                      if (!RegExp(r'^#([A-Fa-f0-9]{6})$').hasMatch(val.trim())) return 'Invalid Hex format';
                      return null;
                    },
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 32),

                  Text('Admin Credentials Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Admin Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Admin Email Address',
                      prefixIcon: Icon(Icons.email_rounded),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter admin email';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 16),

                  // Admin Temp Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Temporary Admin Password',
                      prefixIcon: Icon(Icons.lock_rounded),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Enter temp password';
                      if (val.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 32),

                  _isSaving
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.add_business_rounded),
                          label: const Text('Register School & Admin'),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
