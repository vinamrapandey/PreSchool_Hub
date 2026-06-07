import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolBranding {
  final String schoolId;
  final String schoolName;
  final String logoUrl;
  final String primaryColorHex;
  final bool isActive;

  SchoolBranding({
    required this.schoolId,
    required this.schoolName,
    required this.logoUrl,
    required this.primaryColorHex,
    required this.isActive,
  });

  /// Factory constructor to create a [SchoolBranding] from a Firestore [DocumentSnapshot].
  factory SchoolBranding.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SchoolBranding(
      schoolId: doc.id,
      schoolName: data['schoolName'] as String? ?? '',
      logoUrl: data['logoUrl'] as String? ?? '',
      primaryColorHex: data['primaryColorHex'] as String? ?? '#4A90D9',
      isActive: data['isActive'] as bool? ?? false,
    );
  }

  /// Converts the branding details into a map structure.
  Map<String, dynamic> toMap() {
    return {
      'schoolName': schoolName,
      'logoUrl': logoUrl,
      'primaryColorHex': primaryColorHex,
      'isActive': isActive,
    };
  }

  /// Creates a copy of this branding configuration but with the given fields replaced.
  SchoolBranding copyWith({
    String? schoolId,
    String? schoolName,
    String? logoUrl,
    String? primaryColorHex,
    bool? isActive,
  }) {
    return SchoolBranding(
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      logoUrl: logoUrl ?? this.logoUrl,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      isActive: isActive ?? this.isActive,
    );
  }
}
