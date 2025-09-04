// screens/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../providers/user_provider.dart';
import 'main_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return StreamBuilder<User?>(
      stream: authService.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;

          if (user != null) {
            // User is signed in, fetch user data
            WidgetsBinding.instance.addPostFrameCallback((_) {
              userProvider.fetchUserData(user.uid);
            });

            // Make sure to return the MainScreen with access to providers
            return const MainScreen();
          } else {
            // User is not signed in
            return const LoginScreen();
          }
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
