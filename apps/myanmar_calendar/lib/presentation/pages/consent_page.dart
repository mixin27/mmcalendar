import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:settings/settings.dart';

class ConsentPage extends StatefulWidget {
  const ConsentPage({super.key});

  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo/Icon section
              Column(
                children: [
                  const SizedBox(height: 32),
                  Icon(
                    Icons.privacy_tip_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Help Us Improve',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Myanmar Calendar would like to collect analytics '
                    'and crash reports to help improve your experience.\n\n'
                    'This data is never shared with third parties.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),

              // Buttons section
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: _isProcessing
                        ? null
                        : () => _handleAccept(context),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enable All'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _isProcessing
                        ? null
                        : () => _handleDecline(context),
                    child: const Text('Disable All'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'You can change these settings anytime in '
                    'Settings > Privacy & Data',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAccept(BuildContext context) async {
    setState(() => _isProcessing = true);

    try {
      // Mark consent dialog as shown
      context.read<SettingsBloc>().add(const MarkConsentDialogShown());

      // Wait a moment for bloc to update
      await Future.delayed(const Duration(milliseconds: 500));

      if (context.mounted) {
        // Navigate to home
        context.go(RoutePaths.home);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleDecline(BuildContext context) async {
    setState(() => _isProcessing = true);

    try {
      final settingsBloc = context.read<SettingsBloc>();

      // Disable analytics and crashlytics
      settingsBloc.add(const UpdateAnalyticsConsent(false));
      settingsBloc.add(const UpdateCrashlyticsConsent(false));

      // Mark consent dialog as shown
      settingsBloc.add(const MarkConsentDialogShown());

      // Wait for bloc to update
      await Future.delayed(const Duration(milliseconds: 500));

      if (context.mounted) {
        // Navigate to home
        context.go(RoutePaths.home);

        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Analytics disabled. You can enable it in Settings.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isProcessing = false);
      }
    }
  }
}
