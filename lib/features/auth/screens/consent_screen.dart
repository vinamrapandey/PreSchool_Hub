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
  bool _isGuardianConfirmed = false;
  bool _isDataConsentGiven = false;
  bool _isSaving = false;

  Future<void> _acceptConsent() async {
    if (!_isGuardianConfirmed || !_isDataConsentGiven) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection(FirebaseConstants.kColUsers)
            .doc(user.uid)
            .update({
          'consentGiven': true,
          'consentTimestamp': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Consent submitted successfully! Welcome to the portal.'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/parent');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save consent: ${e.toString()}'),
            backgroundColor: Colors.red,
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

  Future<void> _declineAndLogout() async {
    setState(() {
      _isSaving = true;
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
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schoolBranding = ref.watch(brandingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(schoolBranding?.schoolName ?? 'Preschool Portal'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.security_rounded,
                          color: theme.colorScheme.primary,
                          size: 36,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'DPDP Consent Notice',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'In compliance with the Digital Personal Data Protection (DPDP) Act, 2023 (India), we require your explicit, informed consent to collect and process your child\'s personal data.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      '1. Nature of Data Collected',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'We collect the following personal data of your child:\n'
                      '• Student Profile details: Name, date of birth, gender, and photograph.\n'
                      '• Academic & Classroom updates: Group photos/videos of classroom activities.\n'
                      '• Daily Operations data: Attendance records, teacher logs, and notices.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '2. Purpose of Data Processing',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'The collected data is processed strictly for the following purposes:\n'
                      '• To share classroom activity updates and photos/videos with you.\n'
                      '• To manage preschool/daycare attendance tracking and safety.\n'
                      '• To send urgent school notices, notifications, and emergency alerts.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '3. Your Rights as a Parent (Data Principal)',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Under the DPDP Act 2023, you have the right to:\n'
                      '• Access the personal data we process regarding your child.\n'
                      '• Correct, update, or complete any inaccurate data.\n'
                      '• Withdraw your consent at any time, which may result in limited app functionality.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Guardian Confirmation Checkbox
                    CheckboxListTile(
                      value: _isGuardianConfirmed,
                      onChanged: _isSaving
                          ? null
                          : (val) {
                              setState(() {
                                _isGuardianConfirmed = val ?? false;
                              });
                            },
                      title: const Text(
                        'I confirm that I am the parent or lawful guardian of the child registered under this account.',
                        style: TextStyle(fontSize: 14),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),

                    // Data Consent Checkbox
                    CheckboxListTile(
                      value: _isDataConsentGiven,
                      onChanged: _isSaving
                          ? null
                          : (val) {
                              setState(() {
                                _isDataConsentGiven = val ?? false;
                              });
                            },
                      title: const Text(
                        'I give my clear, specific, and informed consent to process my child\'s personal data for the educational and operational purposes described above.',
                        style: TextStyle(fontSize: 14),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 32),

                    // Actions Row
                    if (_isSaving)
                      const Center(child: CircularProgressIndicator())
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _declineAndLogout,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: theme.colorScheme.error),
                                foregroundColor: theme.colorScheme.error,
                              ),
                              child: const Text('Decline & Logout'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: (_isGuardianConfirmed && _isDataConsentGiven)
                                  ? _acceptConsent
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                              ),
                              child: const Text('Accept & Continue'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
