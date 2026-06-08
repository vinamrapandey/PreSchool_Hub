import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/firebase_constants.dart';
import '../../../core/providers/branding_provider.dart';
import '../../../shared/models/school_branding.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _schoolCodeFormKey = GlobalKey<FormState>();
  final _loginFormKey = GlobalKey<FormState>();

  final _schoolCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _schoolCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Queries Firestore to find the school branding matching the entered code.
  Future<void> _findSchool() async {
    if (!_schoolCodeFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final enteredCode = _schoolCodeController.text.trim();

    // --- TEMPORARY SEED LOGIC ---
    if (enteredCode == 'seed') {
      try {
        await FirebaseFirestore.instance.collection(FirebaseConstants.kColSchools).doc('test1234').set({
          'schoolId': 'test1234',
          'schoolName': 'Test PreSchool',
          'logoUrl': '',
          'primaryColorHex': '#4A90D9',
          'isActive': true,
        });

        Future<void> createMockUser(String email, String role, String displayName) async {
          try {
            final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: email,
              password: 'password123',
            );
            await FirebaseFirestore.instance.collection(FirebaseConstants.kColUsers).doc(userCred.user!.uid).set({
              'uid': userCred.user!.uid,
              'email': email,
              'displayName': displayName,
              'role': role,
              'schoolId': 'test1234',
              'consentGiven': false,
            });
            if (role == 'super_admin') {
              await FirebaseFirestore.instance.collection('super_admins').doc(userCred.user!.uid).set({
                'uid': userCred.user!.uid,
                'email': email,
              });
            }
          } catch (e) {
            // Ignore if user already exists
          }
        }
        
        await createMockUser('parent@test.com', 'parent', 'Test Parent');
        await createMockUser('teacher@test.com', 'teacher', 'Test Teacher');
        await createMockUser('admin@test.com', 'admin', 'Test Admin');
        await createMockUser('superadmin@test.com', 'super_admin', 'Test Super Admin');
        
        final parentQuery = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: 'parent@test.com').get();
        if (parentQuery.docs.isNotEmpty) {
          final parentUid = parentQuery.docs.first.id;
          
          await FirebaseFirestore.instance.collection('students').doc('child1').set({
            'schoolId': 'test1234',
            'classId': 'classA',
            'name': 'Arjun',
            'parentUids': [parentUid],
            'photoUrl': '',
          });

          await FirebaseFirestore.instance.collection('daily_reports').doc('report1').set({
            'schoolId': 'test1234',
            'studentId': 'child1',
            'classId': 'classA',
            'date': DateTime.now().toIso8601String().substring(0, 10),
            'mood': 'happy',
            'breakfast': 'ateWell',
            'lunch': 'ateWell',
            'snack': 'notApplicable',
            'napDuration': '45 min',
            'teacherNote': 'Arjun had a great day today! He really enjoyed the painting activity.',
            'teacherUid': 'teacher1',
            'timestamp': Timestamp.now(),
          });

          await FirebaseFirestore.instance.collection('notices').doc('notice1').set({
            'schoolId': 'test1234',
            'title': 'Annual Sports Day',
            'body': 'Please remember to send your child in sports uniform tomorrow.',
            'targetRoles': ['parent'],
            'createdByUid': 'admin1',
            'timestamp': Timestamp.now(),
            'isActive': true,
            'isPinned': true,
            'targetClassId': null,
          });

          await FirebaseFirestore.instance.collection('activity_posts').doc('post1').set({
            'schoolId': 'test1234',
            'classId': 'classA',
            'teacherUid': 'teacher1',
            'teacherName': 'Miss Sarah',
            'content': 'Finger painting session! We learned about mixing primary colors.',
            'activityType': 'Art',
            'mediaUrls': [],
            'targetRoles': ['parent'],
            'timestamp': Timestamp.now(),
          });
        }
        
        _showErrorSnackBar('Seed complete! Test data populated for Parent Panel.');
      } catch (e) {
        _showErrorSnackBar('Seed error: $e');
      } finally {
        setState(() => _isLoading = false);
      }
      return;
    }
    // --- END SEED LOGIC ---

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection(FirebaseConstants.kColSchools)
          .doc(enteredCode)
          .get();

      if (docSnapshot.exists) {
        final branding = SchoolBranding.fromFirestore(docSnapshot);
        if (branding.isActive) {
          ref.read(brandingProvider.notifier).setBranding(branding);
        } else {
          _showErrorSnackBar('School is inactive. Please contact your administrator.');
        }
      } else {
        _showErrorSnackBar('School not found. Please check your school code.');
      }
    } catch (e) {
      _showErrorSnackBar('Error retrieving school details: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Authenticates credentials using Firebase Auth
  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (mounted) {
        context.go('/role-check');
      }
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(e.message ?? 'Authentication failed.');
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(brandingProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: branding == null
                    ? _buildSchoolCodeStage(theme)
                    : _buildLoginFormStage(theme, branding),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Stage 1 Layout: School Code Entry
  Widget _buildSchoolCodeStage(ThemeData theme) {
    return Card(
      key: const ValueKey('school_code_stage'),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _schoolCodeFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Logo/Icon Placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.school_rounded,
                  size: 40,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'PreSchool Hub',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your school code to connect with your school portal.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // School Code Field
              TextFormField(
                controller: _schoolCodeController,
                decoration: const InputDecoration(
                  labelText: 'School Code',
                  hintText: 'e.g. greenwood_preschool',
                  prefixIcon: Icon(Icons.vpn_key_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a school code';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _findSchool(),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),
              
              // Search Button
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _findSchool,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Find School'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  /// Stage 2 Layout: Account Credentials Login
  Widget _buildLoginFormStage(ThemeData theme, SchoolBranding branding) {
    return Card(
      key: const ValueKey('login_form_stage'),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _loginFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dynamic School Logo
              branding.logoUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: branding.logoUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 80,
                          height: 80,
                          color: theme.colorScheme.surfaceContainerHigh,
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 80,
                          height: 80,
                          color: theme.colorScheme.primaryContainer,
                          child: Icon(
                            Icons.school_rounded,
                            size: 40,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.school_rounded,
                        size: 40,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
              const SizedBox(height: 16),
              
              // Dynamic School Name
              Text(
                branding.schoolName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email address';
                  }
                  final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegExp.hasMatch(value.trim())) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              
              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _login(),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),
              
              // Login Button
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Login'),
                          SizedBox(width: 8),
                          Icon(Icons.login_rounded, size: 20),
                        ],
                      ),
                    ),
              const SizedBox(height: 16),
              
              // Reset School Code Option
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        ref.read(brandingProvider.notifier).clearBranding();
                        _schoolCodeController.clear();
                        _emailController.clear();
                        _passwordController.clear();
                      },
                child: Text(
                  'Change School',
                  style: TextStyle(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
