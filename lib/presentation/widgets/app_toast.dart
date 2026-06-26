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
    final messenger = ScaffoldMessenger.of(context);

    // Premium dark mode styling based on user request
    final bgColor = isDark
        ? colorScheme.primary.withValues(alpha: 0.15)
        : colorScheme.primary.withValues(alpha: 0.9);

    final borderColor = isDark
        ? colorScheme.primary.withValues(alpha: 0.4)
        : colorScheme.primary;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: _ToastContent(
            message: message,
            actionLabel: actionLabel,
            onAction: onAction == null
                ? null
                : () {
                    messenger.hideCurrentSnackBar();
                    onAction();
                  },
          ),
          behavior: SnackBarBehavior.floating,
          duration: duration,
          backgroundColor: bgColor,
          elevation: 0, // Remove shadow so the transparency looks cleaner
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor, width: 1.5),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      );

    // Force hide just in case accessibility settings or bugs keep it open
    Future.delayed(duration, () {
      messenger.hideCurrentSnackBar();
    });
  }
}

class _ToastContent extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ToastContent({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final actionLabel = this.actionLabel;
    final onAction = this.onAction;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(width: 12),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }
}
