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
        // Auth Service
        Provider<AuthService>(create: (_) => AuthService()),

        // User Provider with initialization
        ChangeNotifierProvider<UserProvider>(
          create: (context) {
            final userProvider = UserProvider();
            // Initialize after a small delay to ensure Firebase is ready
            Future.delayed(const Duration(milliseconds: 100), () {
              userProvider.initialize();
            });
            return userProvider;
          },
        ),

        // Crime Data Provider
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
