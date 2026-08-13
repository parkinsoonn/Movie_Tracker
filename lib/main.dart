// ---------------------------------------------------------------------------
// main.dart
// ---------------------------------------------------------------------------
// Entry point for the Cinephile movie tracking app.
//
// Initialises Firebase and applies the Cinematic Noir theme system.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/app_theme.dart';
import 'screens/auth/login_screeen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MovieTrackerApp());
}

class MovieTrackerApp extends StatelessWidget {
  const MovieTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cinephile',
      theme: CinephileTheme.buildTheme(),
      home: const LoginScreen(),
    );
  }
}