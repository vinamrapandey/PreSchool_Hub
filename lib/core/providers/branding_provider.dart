import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/school_branding.dart';

class BrandingNotifier extends StateNotifier<SchoolBranding?> {
  BrandingNotifier() : super(null);

  /// Sets the active school branding configurations.
  void setBranding(SchoolBranding branding) {
    state = branding;
  }

  /// Clears the active school branding, resetting the app to default branding.
  void clearBranding() {
    state = null;
  }
}

/// A global provider to access the current school's branding state.
final brandingProvider = StateNotifierProvider<BrandingNotifier, SchoolBranding?>((ref) {
  return BrandingNotifier();
});
