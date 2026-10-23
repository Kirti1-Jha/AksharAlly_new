import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, debugPrintStack, kDebugMode;
import 'firebase_options.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_gate.dart';
import 'theme/accessibility_settings.dart';
import 'theme/ui_accessibility.dart';
import 'services/library_storage.dart';
import 'theme/app_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore reader accessibility preferences before the first frame.
  await AccessibilitySettings.load();
  // Restore UI accessibility preferences (font, spacing, color theme).
  await UIAccessibility.load();
  // Hydrate reading history from SharedPreferences before the first frame.
  await LibraryStorage.load();
  await AppSettings.loadVoiceAssistancePreference();
  runApp(const AppInitializer());
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late final Future<FirebaseApp> _firebaseInit;

  @override
  void initState() {
    super.initState();
    _firebaseInit = _initializeFirebase();
  }

  Future<FirebaseApp> _initializeFirebase() async {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      if (kDebugMode) {
        debugPrint(
          'FIREBASE_INIT start projectId=${options.projectId} '
          'appId=${options.appId}',
        );
      }
      final app = await Firebase.initializeApp(options: options);
      if (kDebugMode) {
        debugPrint(
          'FIREBASE_INIT result=success projectId=${app.options.projectId} '
          'appId=${app.options.appId}',
        );
      }
      return app;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        if (error is FirebaseException) {
          debugPrint(
            'FIREBASE_INIT result=error plugin=${error.plugin} '
            'code=${error.code} message=${error.message}',
          );
        } else {
          debugPrint('FIREBASE_INIT result=error type=${error.runtimeType}');
        }
        debugPrintStack(stackTrace: stackTrace);
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _firebaseInit,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: Text("Firebase Error: ${snapshot.error}")),
            ),
          );
        }

        return const AksharAllyApp();
      },
    );
  }
}

/// Root app widget.  Wrapped in ValueListenableBuilder so that every time
/// UIAccessibility.notifier fires the MaterialApp rebuilds with the new
/// ThemeData — instant global font/colour propagation, no Provider needed.
class AksharAllyApp extends StatelessWidget {
  const AksharAllyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: UIAccessibility.notifier,
      builder: (_, __, ___) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: UIAccessibility.buildTheme(),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) {
            final requestedUid =
                ModalRoute.of(context)?.settings.arguments as String?;
            return OnboardingGate(
              uid: requestedUid ?? FirebaseAuth.instance.currentUser?.uid,
            );
          },
        },
      ),
    );
  }
}
