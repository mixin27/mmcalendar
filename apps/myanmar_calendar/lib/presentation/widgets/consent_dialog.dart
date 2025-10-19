import 'package:flutter/material.dart';
import 'package:settings/settings.dart';

void showConsentDialog(BuildContext context, SettingsBloc settingsBloc) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(Icons.privacy_tip_outlined, size: 32),
      title: const Text('Help Us Improve'),
      content: const Text(
        'Myanmar Calendar would like to collect analytics and '
        'crash reports to help improve your experience. '
        'This data is never shared with third parties. '
        '\n\nYou can change these settings anytime in Settings > Privacy & Data.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Disable all
            settingsBloc.add(const UpdateAnalyticsConsent(false));
            settingsBloc.add(const UpdateCrashlyticsConsent(false));

            // Mark dialog as shown
            settingsBloc.add(const MarkConsentDialogShown());

            Navigator.pop(dialogContext);

            // Show confirmation
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Analytics disabled. You can change this in Settings.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: const Text('Disable All'),
        ),
        FilledButton(
          onPressed: () {
            // Mark dialog as shown (keep defaults enabled)
            settingsBloc.add(const MarkConsentDialogShown());

            Navigator.pop(dialogContext);

            // Show confirmation
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Thank you! Analytics enabled. You can change this in Settings.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: const Text('Enable All'),
        ),
      ],
    ),
  );
}
