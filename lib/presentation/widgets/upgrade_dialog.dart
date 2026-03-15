import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logic_canvas/presentation/cubits/entitlements/entitlements_cubit.dart';

class UpgradeDialog {
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final isPro = context.read<EntitlementsCubit>().state.isPro;
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Unlock Pro'),
          content: const Text(
            'Pro unlocks the full problem library, smart tools (handwriting + shapes), and the full icon library.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Not now'),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Purchases not wired yet (IAP coming next).')),
                );
              },
              child: const Text('View pricing'),
            ),
            if (kDebugMode)
              TextButton(
                onPressed: () async {
                  await context.read<EntitlementsCubit>().setPro(!isPro);
                  if (context.mounted) Navigator.of(dialogContext).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: isPro ? Colors.orangeAccent : Colors.greenAccent,
                ),
                child: Text(isPro ? 'Dev: Switch to Free' : 'Dev: Unlock Pro'),
              ),
          ],
        );
      },
    );
  }
}
