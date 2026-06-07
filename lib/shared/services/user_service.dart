import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firebase_constants.dart';
import '../models/app_user.dart';

class UserService {
  final FirebaseFirestore _firestore;

  UserService(this._firestore);

  /// Retrieves an [AppUser] document from Firestore by its UID.
  Future<AppUser?> getUserByUid(String uid) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.kColUsers)
          .doc(uid)
          .get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Creates or merges user details into Firestore.
  Future<void> saveUser(AppUser user) async {
    try {
      await _firestore
          .collection(FirebaseConstants.kColUsers)
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for the [UserService] class to enable dependency injection.
final userServiceProvider = Provider<UserService>((ref) {
  return UserService(FirebaseFirestore.instance);
});
