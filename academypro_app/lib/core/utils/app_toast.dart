import 'package:flutter/material.dart';

class AppToast {
  /// Displays a modern, floating toast near the top of the screen
  /// ensuring high visibility without obscuring bottom nav bars or modal sheets.
  static void showSuccess(BuildContext context, {required String title, String? message}) {
    _showToast(
      context,
      title: title,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: const Color(0xFF0F172A),
      accentColor: const Color(0xFF10B981),
    );
  }

  static void showError(BuildContext context, {required String title, String? message}) {
    _showToast(
      context,
      title: title,
      message: message,
      icon: Icons.error_outline_rounded,
      backgroundColor: const Color(0xFF7F1D1D),
      accentColor: const Color(0xFFF87171),
    );
  }

  static void showInfo(BuildContext context, {required String title, String? message}) {
    _showToast(
      context,
      title: title,
      message: message,
      icon: Icons.info_outline_rounded,
      backgroundColor: const Color(0xFF003EC7),
      accentColor: const Color(0xFF60A5FA),
    );
  }

  static void _showToast(
    BuildContext context, {
    required String title,
    String? message,
    required IconData icon,
    required Color backgroundColor,
    required Color accentColor,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final double mediaHeight = MediaQuery.of(context).size.height;
    final double topMargin = MediaQuery.of(context).padding.top + 16.0;

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 8.0,
        backgroundColor: Colors.transparent,
        duration: const Duration(seconds: 4),
        margin: EdgeInsets.only(
          bottom: (mediaHeight - topMargin - 85.0).clamp(100.0, 2000.0),
          left: 16.0,
          right: 16.0,
        ),
        padding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 14.0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 20.0),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (message != null && message.trim().isNotEmpty) ...[
                      const SizedBox(height: 2.0),
                      Text(
                        message,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
