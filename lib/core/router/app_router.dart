import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/firebase_constants.dart';
import '../../shared/models/app_user.dart';
import '../../shared/services/user_service.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/role_check_screen.dart';
import '../../features/auth/screens/consent_screen.dart';
import '../../features/parent/screens/parent_dashboard_screen.dart';
import '../../features/teacher/screens/teacher_dashboard_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/management/screens/management_dashboard_screen.dart';
import '../../features/super_admin/screens/super_admin_dashboard_screen.dart';

/// StreamProvider that listens to authentication state changes.
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Family provider to fetch a user document dynamically by UID.
final appUserProvider = FutureProvider.family.autoDispose<AppUser?, String>((ref, uid) async {
  final userService = ref.read(userServiceProvider);
  return userService.getUserByUid(uid);
});

/// A [ChangeNotifier] that listens to a stream and notifies listeners to trigger GoRouter refreshes.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Provider exposing the configured [GoRouter] instance.
final routerProvider = Provider<GoRouter>((ref) {
  final authStream = FirebaseAuth.instance.authStateChanges();

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authStream),
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
        builder: (context, state) => const SuperAdminDashboardScreen(),
      ),
    ],
    redirect: (context, state) async {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggingIn = state.matchedLocation == '/login';

      // 1. No auth user -> /login
      if (user == null) {
        return isLoggingIn ? null : '/login';
      }

      // 2. Auth user present, path is /login -> /role-check
      if (isLoggingIn) {
        return '/role-check';
      }

      // 3. Super admin check (uid exists in super_admins collection)
      try {
        final superAdminDoc = await FirebaseFirestore.instance
            .collection(FirebaseConstants.kColSuperAdmins)
            .doc(user.uid)
            .get();

        if (superAdminDoc.exists) {
          return state.matchedLocation == '/super-admin' ? null : '/super-admin';
        }
      } catch (_) {
        // Fallback on read errors (such as security rule restricts)
      }

      // 4. Otherwise: role-check handles routing to correct dashboard
      return null;
    },
  );
});
