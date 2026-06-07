enum UserRole {
  parent,
  teacher,
  admin,
  management,
  superAdmin,
}

extension UserRoleX on UserRole {
  /// Converts the enum value to the string representation stored in Firestore.
  String toFirestoreValue() {
    switch (this) {
      case UserRole.parent:
        return 'parent';
      case UserRole.teacher:
        return 'teacher';
      case UserRole.admin:
        return 'admin';
      case UserRole.management:
        return 'management';
      case UserRole.superAdmin:
        return 'superAdmin';
    }
  }

  /// Parses a string value from Firestore back into a [UserRole] enum.
  static UserRole fromString(String val) {
    switch (val) {
      case 'parent':
        return UserRole.parent;
      case 'teacher':
        return UserRole.teacher;
      case 'admin':
        return UserRole.admin;
      case 'management':
        return UserRole.management;
      case 'superAdmin':
      case 'superadmin':
        return UserRole.superAdmin;
      default:
        throw ArgumentError('Invalid user role: $val');
    }
  }
}
