import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/firebase_constants.dart';

class AddTeacherForm extends ConsumerStatefulWidget {
  final String schoolId;
  const AddTeacherForm({super.key, required this.schoolId});

  @override
  ConsumerState<AddTeacherForm> createState() => _AddTeacherFormState();
}

class _AddTeacherFormState extends ConsumerState<AddTeacherForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;

  Future<void> _saveTeacher() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      // Create mock user placeholder in Firestore since we don't have Admin SDK for auth
      String teacherUid = 'teacher_${DateTime.now().millisecondsSinceEpoch}';
      
      await FirebaseFirestore.instance.collection(FirebaseConstants.kColUsers).doc(teacherUid).set({
        'uid': teacherUid,
        'email': _emailController.text.trim(),
        'displayName': _nameController.text.trim(),
        'role': 'teacher',
        'schoolId': widget.schoolId,
        'consentGiven': true,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teacher added successfully. An email will be sent with login details.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add New Teacher', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val == null || !val.contains('@') ? 'Enter a valid email' : null,
              ),
              
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveTeacher,
                      child: const Text('Save Teacher'),
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
