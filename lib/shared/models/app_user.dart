import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_role.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String schoolId;
  final String? fcmToken;
  final bool consentGiven;
  final Timestamp? consentTimestamp;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.schoolId,
    this.fcmToken,
    this.consentGiven = false,
    this.consentTimestamp,
  });

  /// Factory constructor to build an [AppUser] from a Firestore [DocumentSnapshot].
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final roleStr = data['role'] as String? ?? 'parent';
    
    return AppUser(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role: UserRoleX.fromString(roleStr),
      schoolId: data['schoolId'] as String? ?? '',
      fcmToken: data['fcmToken'] as String?,
      consentGiven: data['consentGiven'] as bool? ?? false,
      consentTimestamp: data['consentTimestamp'] as Timestamp?,
    );
  }

  /// Converts the user model into a map for Firestore writes.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role.toFirestoreValue(),
      'schoolId': schoolId,
      'fcmToken': fcmToken,
      'consentGiven': consentGiven,
      'consentTimestamp': consentTimestamp,
    };
  }

  /// Returns a copy of the user with updated fields.
  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    String? schoolId,
    String? fcmToken,
    bool? consentGiven,
    Timestamp? consentTimestamp,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      schoolId: schoolId ?? this.schoolId,
      fcmToken: fcmToken ?? this.fcmToken,
      consentGiven: consentGiven ?? this.consentGiven,
      consentTimestamp: consentTimestamp ?? this.consentTimestamp,
    );
  }
}
