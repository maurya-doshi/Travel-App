import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_hackathon/core/theme/premium_theme.dart';
import 'core/router/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:travel_hackathon/firebase_options.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  // Check for Persistent Session
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('user_id');

  runApp(ProviderScope(
    overrides: [
      if (userId != null) currentUserProvider.overrideWith((ref) => userId),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Tourism App',
      debugShowCheckedModeBanner: false,
      theme: PremiumTheme.lightTheme,
      routerConfig: router,
    );
  }
}
