import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'theme/accessibility_settings.dart';
import 'theme/ui_accessibility.dart';
import 'services/library_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore reader accessibility preferences before the first frame.
  await AccessibilitySettings.load();
  // Restore UI accessibility preferences (font, spacing, color theme).
  await UIAccessibility.load();
  // Hydrate reading history from SharedPreferences before the first frame.
  await LibraryStorage.load();
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
    _firebaseInit = Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _firebaseInit,
      builder: (context, snapshot) {

        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text("Firebase Error: ${snapshot.error}"),
              ),
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
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}