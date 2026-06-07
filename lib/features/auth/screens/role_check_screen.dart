import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/firebase_constants.dart';
import '../../../core/providers/branding_provider.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/school_branding.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/services/user_service.dart';

class RoleCheckScreen extends ConsumerStatefulWidget {
  const RoleCheckScreen({super.key});

  @override
  ConsumerState<RoleCheckScreen> createState() => _RoleCheckScreenState();
}

class _RoleCheckScreenState extends ConsumerState<RoleCheckScreen> {
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserRole();
    });
  }

  Future<void> _checkUserRole() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) context.go('/login');
      return;
    }

    try {
      // 1. Check if user is a registered Super Admin first (existence of doc in super_admins collection)
      final superAdminDoc = await FirebaseFirestore.instance
          .collection(FirebaseConstants.kColSuperAdmins)
          .doc(currentUser.uid)
          .get();

      if (superAdminDoc.exists) {
        if (mounted) {
          context.go('/super-admin');
        }
        return;
      }

      // 2. Fetch standard user profile
      final userService = ref.read(userServiceProvider);
      final appUser = await userService.getUserByUid(currentUser.uid);

      if (appUser == null) {
        setState(() {
          _errorMessage = 'Account not set up. Contact your school admin.';
          _isLoading = false;
        });
        return;
      }

      // 3. Load tenant branding details if the user has a designated schoolId
      if (appUser.schoolId.isNotEmpty) {
        final schoolDoc = await FirebaseFirestore.instance
            .collection(FirebaseConstants.kColSchools)
            .doc(appUser.schoolId)
            .get();

        if (schoolDoc.exists) {
          final branding = SchoolBranding.fromFirestore(schoolDoc);
          if (branding.isActive) {
            ref.read(brandingProvider.notifier).setBranding(branding);
          } else {
            setState(() {
              _errorMessage = 'Your school portal is currently inactive. Contact admin.';
              _isLoading = false;
            });
            return;
          }
        }
      }

      // 4. Redirect based on role and DPDP consent requirement
      if (!mounted) return;

      if (appUser.role == UserRole.superAdmin) {
        context.go('/super-admin');
      } else if (appUser.role == UserRole.parent) {
        if (!appUser.consentGiven) {
          context.go('/consent');
        } else {
          context.go('/parent');
        }
      } else {
        context.go('/${appUser.role.toFirestoreValue()}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred during verification: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signOut();
      ref.read(brandingProvider.notifier).clearBranding();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to log out: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  'Verifying your account details...',
                  style: theme.textTheme.titleMedium,
                ),
              ] else if (_errorMessage != null) ...[
                Icon(
                  Icons.error_outline_rounded,
                  color: theme.colorScheme.error,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Access Denied',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Back to Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.errorContainer,
                    foregroundColor: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
