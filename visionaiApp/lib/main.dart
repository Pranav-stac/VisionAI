import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:visionai/providers/scene_description_provider.dart';
import 'package:visionai/screens/splash_screen.dart';
import 'package:visionai/screens/onboarding/onboarding_screen.dart';
import 'package:visionai/screens/auth/login_screen.dart';
import 'package:visionai/screens/home/home_screen.dart';
import 'package:visionai/theme/dark_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'screens/features/mental_health_screen.dart';
import 'package:visionai/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:visionai/providers/language_provider.dart';
import 'package:visionai/screens/settings/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCy6FET69_SR2RX2B2OOoKiS4t-1LGP-b0",
        authDomain: "vision-ai-f6345.firebaseapp.com",
        databaseURL: "https://vision-ai-f6345-default-rtdb.firebaseio.com",
        projectId: "vision-ai-f6345",
        storageBucket: "vision-ai-f6345.firebasestorage.app",
        messagingSenderId: "335489594965",
        appId: "1:335489594965:android:11bec921f481d9354ec6dc",
      ),
    );
    
    // Initialize App Check
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
      );
    } catch (e) {
      print('App Check activation error (non-critical): $e');
    }
    
    // Configure Firebase Database
    try {
      FirebaseDatabase.instance.setPersistenceEnabled(true);
      FirebaseDatabase.instance.ref().keepSynced(true);
    } catch (dbError) {
      print('Error configuring Firebase Database: $dbError');
    }
    
    // Initialize a dummy user since we're bypassing login
    final AuthService authService = AuthService();
    await authService.dummySignInWithGoogle();
    print('Initialized app with dummy user');
    
  } catch (e) {
    print('Error initializing Firebase: $e');
    // You might want to show an error dialog or handle the error appropriately
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/mental-health',
      builder: (context, state) => const MentalHealthScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SceneDescriptionProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, _) {
          return MaterialApp.router(
            title: 'Vision AI',
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
            theme: AppTheme.getDarkTheme(),
            darkTheme: AppTheme.getDarkTheme(),
            themeMode: ThemeMode.dark,
          );
        },
      ),
    );
  }
}
