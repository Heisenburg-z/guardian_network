// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Screens
import 'screens/main_screen.dart';
import 'screens/auth_wrapper.dart';

// Providers
import 'models/crime_data_provider.dart';
import 'providers/user_provider.dart';

// Services
import 'services/auth_service.dart';

// Theme
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const GuardianNetworkApp());
}

class GuardianNetworkApp extends StatelessWidget {
  const GuardianNetworkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Service (not change notifier, so use Provider)
        Provider<AuthService>(create: (_) => AuthService()),

        // User Provider (change notifier)
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(),
          lazy: false, // Add this to ensure it's created immediately
        ),

        // Crime Data Provider (your existing provider)
        ChangeNotifierProvider<CrimeDataProvider>(
          create: (context) => CrimeDataProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Guardian Network',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
