import 'package:flutter/material.dart';

class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Premium dark mode styling based on user request
    final bgColor = isDark 
        ? colorScheme.primary.withValues(alpha: 0.15) 
        : colorScheme.primary.withValues(alpha: 0.9);
        
    final borderColor = isDark 
        ? colorScheme.primary.withValues(alpha: 0.4) 
        : colorScheme.primary;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: duration,
          backgroundColor: bgColor,
          elevation: 0, // Remove shadow so the transparency looks cleaner
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: borderColor,
              width: 1.5,
            ),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          action: actionLabel != null && onAction != null
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    onAction();
                  },
                )
              : null,
        ),
      );

    // Force hide just in case accessibility settings or bugs keep it open
    Future.delayed(duration, () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    });
  }
}
