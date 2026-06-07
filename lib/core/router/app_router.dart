import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/role_check_screen.dart';
import '../../features/auth/screens/consent_screen.dart';
import '../../features/parent/screens/parent_dashboard_screen.dart';
import '../../features/teacher/screens/teacher_dashboard_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/management/screens/management_dashboard_screen.dart';
import '../../features/super_admin/screens/super_admin_shell.dart';

/// Provider for the [GoRouter] configuration.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/role-check',
        builder: (context, state) => const RoleCheckScreen(),
      ),
      GoRoute(
        path: '/consent',
        builder: (context, state) => const ConsentScreen(),
      ),
      GoRoute(
        path: '/parent',
        builder: (context, state) => const ParentDashboardScreen(),
      ),
      GoRoute(
        path: '/teacher',
        builder: (context, state) => const TeacherDashboardScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/management',
        builder: (context, state) => const ManagementDashboardScreen(),
      ),
      GoRoute(
        path: '/super-admin',
        builder: (context, state) => const SuperAdminShell(),
      ),
    ],
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggingIn = state.matchedLocation == '/login';

      // 1. No Firebase Auth user -> /login
      if (user == null) {
        return isLoggingIn ? null : '/login';
      }

      // 2. Auth user on /login -> /role-check
      if (isLoggingIn) {
        return '/role-check';
      }

      // 3. We will handle other redirections (superAdmin, consent check, and dashboard routing) 
      // in the RoleCheckScreen itself or inside this redirect callback after Firestore providers are set up.
      return null;
    },
  );
});
