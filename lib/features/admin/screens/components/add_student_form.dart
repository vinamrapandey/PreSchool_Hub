import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/firebase_constants.dart';
import '../../../../shared/models/school_class.dart';
import '../../../../shared/services/class_service.dart';
import '../../providers/admin_providers.dart';

class AddStudentForm extends ConsumerStatefulWidget {
  final String schoolId;
  const AddStudentForm({super.key, required this.schoolId});

  @override
  ConsumerState<AddStudentForm> createState() => _AddStudentFormState();
}

class _AddStudentFormState extends ConsumerState<AddStudentForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _parentEmailController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedClassId;
  DateTime? _dob;
  bool _isLoading = false;

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Date of Birth')));
      return;
    }
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a class')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Check if parent exists or create placeholder logic
      // Note: Actual Auth creation should be done via Cloud Functions securely.
      // Here we just write to Firestore for simplicity as requested.
      
      String parentUid = 'parent_${DateTime.now().millisecondsSinceEpoch}';
      final parentEmail = _parentEmailController.text.trim();
      
      if (parentEmail.isNotEmpty) {
        // Just mock creating a parent record in users
        await FirebaseFirestore.instance.collection(FirebaseConstants.kColUsers).doc(parentUid).set({
          'uid': parentUid,
          'email': parentEmail,
          'displayName': _parentNameController.text.trim(),
          'role': 'parent',
          'schoolId': widget.schoolId,
          'consentGiven': false,
        });
      }

      // 2. Create student
      final docRef = FirebaseFirestore.instance.collection('students').doc();
      await docRef.set({
        'schoolId': widget.schoolId,
        'classId': _selectedClassId,
        'name': _nameController.text.trim(),
        'dateOfBirth': Timestamp.fromDate(_dob!),
        'parentUids': parentEmail.isNotEmpty ? [parentUid] : [],
        'notes': _notesController.text.trim(),
        'photoUrl': '',
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student added successfully')));
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
    final classesAsync = ref.watch(classesBySchoolProvider(widget.schoolId));
    
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
              Text('Add New Student', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Student Full Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              
              ListTile(
                title: Text(_dob == null ? 'Select Date of Birth' : 'DOB: ${_dob!.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(const Duration(days: 365 * 4)),
                    firstDate: DateTime(2010),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _dob = date);
                },
              ),
              const SizedBox(height: 12),
              
              classesAsync.when(
                data: (classes) => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Assign to Class'),
                  value: _selectedClassId,
                  items: classes.map((c) => DropdownMenuItem(value: c.classId, child: Text(c.className))).toList(),
                  onChanged: (val) => setState(() => _selectedClassId = val),
                  validator: (val) => val == null ? 'Required' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error loading classes'),
              ),
              
              const Divider(height: 32),
              Text('Parent/Guardian Details', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              
              TextFormField(
                controller: _parentNameController,
                decoration: const InputDecoration(labelText: 'Parent Name (Optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _parentEmailController,
                decoration: const InputDecoration(labelText: 'Parent Email (Optional)'),
                keyboardType: TextInputType.emailAddress,
              ),
              
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Medical Notes / Allergies'),
                maxLines: 3,
              ),
              
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveStudent,
                      child: const Text('Save Student'),
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
