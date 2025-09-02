import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/main_screen.dart';
import 'models/crime_data_provider.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const GuardianNetworkApp());
}

class GuardianNetworkApp extends StatelessWidget {
  const GuardianNetworkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CrimeDataProvider(),
      child: MaterialApp(
        title: 'Guardian Network',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
