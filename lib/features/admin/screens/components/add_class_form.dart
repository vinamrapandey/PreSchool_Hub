import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/services/user_service.dart';
import '../../providers/admin_providers.dart';

class AddClassForm extends ConsumerStatefulWidget {
  final String schoolId;
  const AddClassForm({super.key, required this.schoolId});

  @override
  ConsumerState<AddClassForm> createState() => _AddClassFormState();
}

class _AddClassFormState extends ConsumerState<AddClassForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  String? _selectedTeacherUid;
  bool _isLoading = false;

  Future<void> _saveClass() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final docRef = FirebaseFirestore.instance.collection('classes').doc();
      await docRef.set({
        'schoolId': widget.schoolId,
        'className': _nameController.text.trim(),
        'teacherUid': _selectedTeacherUid ?? '',
        'studentIds': [],
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class added successfully')));
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
    final teachersAsync = ref.watch(teachersBySchoolProvider(widget.schoolId));
    
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
              Text('Add New Class', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Class Name (e.g. Sunflower Class)'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              
              teachersAsync.when(
                data: (teachers) => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Assign Teacher (Optional)'),
                  value: _selectedTeacherUid,
                  items: teachers.map((t) => DropdownMenuItem(value: t.uid, child: Text(t.displayName))).toList(),
                  onChanged: (val) => setState(() => _selectedTeacherUid = val),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error loading teachers'),
              ),
              
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveClass,
                      child: const Text('Save Class'),
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
