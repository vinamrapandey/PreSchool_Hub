import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/firebase_constants.dart';
import '../../../core/providers/branding_provider.dart';

class AdminSettingsTab extends ConsumerStatefulWidget {
  final String schoolId;

  const AdminSettingsTab({super.key, required this.schoolId});

  @override
  ConsumerState<AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends ConsumerState<AdminSettingsTab> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  final List<Map<String, String>> _colorPresets = [
    {'name': 'Indigo Blue', 'hex': '#4A90D9'},
    {'name': 'Crimson Red', 'hex': '#E53935'},
    {'name': 'Emerald Green', 'hex': '#43A047'},
    {'name': 'Amber Orange', 'hex': '#FB8C00'},
    {'name': 'Orchid Purple', 'hex': '#8E24AA'},
    {'name': 'Deep Teal', 'hex': '#008080'},
  ];

  Future<void> _uploadLogo() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      final storage = FirebaseStorage.instance;
      // Fixed storage path schools/{schoolId}/logo/logo.jpg
      final storageRef = storage.ref().child('schools/${widget.schoolId}/logo/logo.jpg');

      if (kIsWeb) {
        await storageRef.putData(await image.readAsBytes());
      } else {
        await storageRef.putFile(File(image.path));
      }

      final downloadUrl = await storageRef.getDownloadURL();

      // Update Firestore schools collection
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.kColSchools)
          .doc(widget.schoolId)
          .update({'logoUrl': downloadUrl});

      // Update local branding provider state instantly
      final currentBranding = ref.read(brandingProvider);
      if (currentBranding != null) {
        ref.read(brandingProvider.notifier).setBranding(
              currentBranding.copyWith(logoUrl: downloadUrl),
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload logo: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _updateThemeColor(String hexColor) async {
    try {
      // Update Firestore
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.kColSchools)
          .doc(widget.schoolId)
          .update({'primaryColorHex': hexColor});

      // Update local provider instantly to animate color change
      final currentBranding = ref.read(brandingProvider);
      if (currentBranding != null) {
        ref.read(brandingProvider.notifier).setBranding(
              currentBranding.copyWith(primaryColorHex: hexColor),
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Primary branding color updated to $hexColor!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update color: ${e.toString()}')),
        );
      }
    }
  }

  Color _parseHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final branding = ref.watch(brandingProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'School Settings & Branding',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 8),
          const Text('Manage your preschool appearance parameters and dynamic theme properties.'),
          const SizedBox(height: 32),

          // School Identity Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(128)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Active Logo View
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: branding?.logoUrl.isNotEmpty ?? false
                            ? CachedNetworkImage(
                                imageUrl: branding!.logoUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                color: theme.colorScheme.primaryContainer,
                                child: Icon(Icons.school_rounded, size: 40, color: theme.colorScheme.onPrimaryContainer),
                              ),
                      ),
                      if (_isUploading)
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
                          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                        ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          branding?.schoolName ?? 'My Preschool',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('School Code: ${widget.schoolId}', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _isUploading ? null : _uploadLogo,
                          icon: const Icon(Icons.upload_file_rounded, size: 18),
                          label: const Text('Update Logo'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: const Size(100, 36),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Seed Colors Customization
          Text('Portal Seed Color Hex', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Select a preset color to immediately shift the application theme across all client devices.'),
          const SizedBox(height: 20),
          
          Wrap(
            spacing: 16.0,
            runSpacing: 16.0,
            children: _colorPresets.map((preset) {
              final presetColor = _parseHex(preset['hex']!);
              final isCurrent = branding?.primaryColorHex.toUpperCase() == preset['hex']!.toUpperCase();

              return Tooltip(
                message: preset['name']!,
                child: GestureDetector(
                  onTap: () => _updateThemeColor(preset['hex']!),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: presetColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrent ? theme.colorScheme.primary : Colors.transparent,
                        width: 3.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: presetColor.withAlpha(80),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: isCurrent
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 28)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
