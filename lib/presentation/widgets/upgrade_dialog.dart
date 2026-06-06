import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logic_canvas/presentation/cubits/entitlements/entitlements_cubit.dart';

class UpgradeDialog {
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final isSubscribed = context.read<EntitlementsCubit>().state.isSubscribed;
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Premium Access'),
          content: const Text(
            'Premium unlocks smart drawing tools (handwriting + shape recognition) and the full architectural icon library.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Navigate to paywall if not subscribed
                if (!isSubscribed) {
                  // The app-wide guard in main.dart handles this if they refresh, 
                  // but for immediate feedback we can trigger paywall view here.
                }
              },
              child: const Text('Upgrade'),
            ),
          ],
        );
      },
    );
  }
}
