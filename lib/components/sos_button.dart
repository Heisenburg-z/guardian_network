import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SOSButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SOSButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorColor.withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: "sos",
        onPressed: onPressed,
        backgroundColor: AppTheme.errorColor,
        child: const Icon(Icons.warning, color: Colors.white, size: 28),
      ),
    );
  }
}
