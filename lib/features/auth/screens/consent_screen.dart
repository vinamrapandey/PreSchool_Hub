import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/firebase_constants.dart';
import '../../../core/providers/branding_provider.dart';

class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _isLoading = false;

  Future<void> _declineAndLogout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signOut();
      ref.read(brandingProvider.notifier).clearBranding();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to logout: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _agreeConsent(String? uid) async {
    if (uid == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.kColUsers)
          .doc(uid)
          .update({
        'consentGiven': true,
        'consentTimestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        context.go('/parent');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit consent: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schoolBranding = ref.watch(brandingProvider);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data & Privacy Consent', style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false, // No back button
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Card(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Scrollable content area
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // School logo & Name
                        Center(
                          child: Column(
                            children: [
                              if (schoolBranding != null && schoolBranding.logoUrl.isNotEmpty == true)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    schoolBranding.logoUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        _buildLogoPlaceholder(theme),
                                  ),
                                )
                              else
                                _buildLogoPlaceholder(theme),
                              const SizedBox(height: 16),
                              Text(
                                schoolBranding?.schoolName ?? 'Preschool Portal',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Body content
                        Text(
                          'Please review the data processing policy below before using the app.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        
                        _buildSection(
                          theme,
                          title: 'What data is collected',
                          content: 'Your child\'s name, date of birth, photo, daily attendance, and activity updates.',
                          icon: Icons.assignment_ind_rounded,
                        ),
                        const SizedBox(height: 20),
                        
                        _buildSection(
                          theme,
                          title: 'Who can access it',
                          content: 'Your school\'s teachers and administrators only.',
                          icon: Icons.people_alt_rounded,
                        ),
                        const SizedBox(height: 20),
                        
                        _buildSection(
                          theme,
                          title: 'How it is stored',
                          content: 'Securely on Google Firebase servers.',
                          icon: Icons.cloud_done_rounded,
                        ),
                        const SizedBox(height: 20),
                        
                        _buildSection(
                          theme,
                          title: 'Your rights',
                          content: 'You may request data deletion by contacting your school administrator.',
                          icon: Icons.gavel_rounded,
                        ),
                        const SizedBox(height: 20),
                        
                        _buildSection(
                          theme,
                          title: 'Consent requirement',
                          content: 'This consent is required to use the app. Declining will sign you out.',
                          icon: Icons.info_outline_rounded,
                        ),
                      ],
                    ),
                  ),
                  
                  // Fixed bottom buttons bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16.0),
                        bottomRight: Radius.circular(16.0),
                      ),
                    ),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _declineAndLogout,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: theme.colorScheme.error, width: 1.5),
                                    foregroundColor: theme.colorScheme.error,
                                  ),
                                  child: const Text('Decline & Logout'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _agreeConsent(user?.uid),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: theme.colorScheme.onPrimary,
                                  ),
                                  child: const Text('I Agree'),
                                ),
                              ),
                            ],
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

  Widget _buildLogoPlaceholder(ThemeData theme) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.school_rounded,
        size: 40,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildSection(ThemeData theme, {required String title, required String content, required IconData icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
