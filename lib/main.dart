import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/branding_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase using platform-specific options.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: PreSchoolHubApp(),
    ),
  );
}

class PreSchoolHubApp extends ConsumerWidget {
  const PreSchoolHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final branding = ref.watch(brandingProvider);

    // Dynamic brand color parsing
    final Color seedColor = branding != null 
        ? _parseHexColor(branding.primaryColorHex)
        : AppTheme.defaultSeedColor;

    return MaterialApp.router(
      title: 'PreSchool Hub',
      theme: AppTheme.lightTheme(seedColor),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }

  /// Parses a Hex string (e.g. "#4A90D9" or "4A90D9") into a Flutter [Color].
  Color _parseHexColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) {
        buffer.write('ff'); // Add opacity if missing
      }
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return AppTheme.defaultSeedColor; // Fallback to default
    }
  }
}
