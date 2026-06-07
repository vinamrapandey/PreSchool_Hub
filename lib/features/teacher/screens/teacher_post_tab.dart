import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/models/activity_post.dart';
import '../../../shared/services/activity_service.dart';
import 'teacher_dashboard_screen.dart';

class TeacherPostTab extends ConsumerStatefulWidget {
  const TeacherPostTab({super.key});

  @override
  ConsumerState<TeacherPostTab> createState() => _TeacherPostTabState();
}

class _TeacherPostTabState extends ConsumerState<TeacherPostTab> {
  final _contentController = TextEditingController();
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isPosting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting images: ${e.toString()}')),
      );
    }
  }

  Future<void> _postUpdate() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter update description text.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final classState = ref.read(teacherClassProvider).value;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (classState == null || currentUser == null) return;

    setState(() {
      _isPosting = true;
    });

    final String schoolId = classState.schoolId;
    // Auto-generate postId using Firestore doc ID
    final String postId = FirebaseFirestore.instance.collection('activities').doc().id;
    final List<String> mediaUrls = [];

    try {
      // 1. Upload Images to Firebase Storage
      final storage = FirebaseStorage.instance;
      for (final imageFile in _selectedImages) {
        final filename = '${DateTime.now().microsecondsSinceEpoch}.jpg';
        final storageRef = storage.ref().child('schools/$schoolId/activities/$postId/$filename');

        if (kIsWeb) {
          final bytes = await imageFile.readAsBytes();
          await storageRef.putData(bytes);
        } else {
          await storageRef.putFile(File(imageFile.path));
        }

        final downloadUrl = await storageRef.getDownloadURL();
        mediaUrls.add(downloadUrl);
      }

      // 2. Save ActivityPost document in Firestore
      final activityService = ref.read(activityServiceProvider);
      final activityPost = ActivityPost(
        postId: postId,
        schoolId: schoolId,
        classId: classState.classId,
        teacherUid: currentUser.uid,
        teacherName: currentUser.displayName ?? 'Teacher',
        content: content,
        mediaUrls: mediaUrls,
        timestamp: Timestamp.now(),
        targetRoles: const ['parent', 'management', 'admin'],
      );

      await activityService.postActivity(activityPost);

      // 3. Reset State on Success
      setState(() {
        _contentController.clear();
        _selectedImages.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Update posted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish update: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classAsync = ref.watch(teacherClassProvider);

    return classAsync.when(
      data: (schoolClass) {
        if (schoolClass == null) {
          return const Center(child: Text('No class assigned to your account.'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share an Update',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Publish activities, updates, or photos for the parents of ${schoolClass.className}.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Description Multi-line Input
              TextFormField(
                controller: _contentController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Update Details',
                  hintText: 'Describe today\'s activities or write notes...',
                  alignLabelWithHint: true,
                ),
                enabled: !_isPosting,
              ),
              const SizedBox(height: 20),

              // Selected Images Thumbnails Row
              if (_selectedImages.isNotEmpty) ...[
                Text(
                  'Selected Images (${_selectedImages.length})',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      final imageFile = _selectedImages[index];

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: kIsWeb
                                  ? Image.network(
                                      imageFile.path,
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(imageFile.path),
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: _isPosting
                                    ? null
                                    : () {
                                        setState(() {
                                          _selectedImages.removeAt(index);
                                        });
                                      },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Photos Select Button
              OutlinedButton.icon(
                onPressed: _isPosting ? null : _pickImages,
                icon: const Icon(Icons.add_photo_alternate_rounded),
                label: const Text('Add Photos'),
              ),
              const SizedBox(height: 32),

              // Posting Loader / Submit Button
              _isPosting
                  ? const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Uploading media and saving update...'),
                        ],
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _postUpdate,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Post Update'),
                    ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
