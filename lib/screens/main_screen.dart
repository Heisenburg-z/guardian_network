import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'map_screen.dart';
import 'alerts_screen.dart';
import 'reports_screen.dart';
import 'profile_screen.dart';
import 'community_screen.dart';
import '../components/custom_navigation_bar.dart';
import '../providers/user_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Don't create screens in advance - build them when needed
  // to ensure they have proper provider context
  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const MapScreen();
      case 1:
        return const AlertsScreen();
      case 2:
        return const ReportsScreen();
      case 3:
        return const CommunityScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const MapScreen();
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _animationController.reverse().then((_) {
        _currentIndex = index;
        _animationController.forward();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ensure UserProvider is available to all child screens
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Scaffold(
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: _getScreen(_currentIndex),
          ),
          bottomNavigationBar: CustomNavigationBar(
            currentIndex: _currentIndex,
            onDestinationSelected: _onTabTapped,
          ),
        );
      },
    );
  }
}
