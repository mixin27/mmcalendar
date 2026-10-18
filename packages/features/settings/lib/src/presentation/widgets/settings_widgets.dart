import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_localizations/shared_localizations.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

import '../../domain/entities/app_settings.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import 'state_widgets.dart';

/// Icon tile colours for settings rows (Clear draws them as tiles,
/// Material as plain icons).
abstract final class SettingsIconColors {
  static const blue = Color(0xFF2F5BEA);
  static const indigo = Color(0xFF4C5BD4);
  static const red = Color(0xFFE5383B);
  static const purple = Color(0xFF8E6CEF);
  static const green = Color(0xFF1F9D63);
  static const orange = Color(0xFFF08A1C);
  static const teal = Color(0xFF16A3B0);
  static const amber = Color(0xFFF2A900);
  static const pink = Color(0xFFE0457B);
  static const gray = Color(0xFF8E8E93);
}

/// A settings sub-page in the app style, with the bloc's loading and error
/// states. [builder] returns the page's groups once settings are loaded.
class SettingsSubPage extends StatelessWidget {
  const SettingsSubPage({
    super.key,
    required this.title,
    required this.builder,
    this.previousTitle,
    this.actions = const [],
  });

  final String title;

  /// Buttons on the trailing side of the nav bar (e.g. Apply).
  final List<Widget> actions;

  /// The back label; defaults to the localized "Settings".
  final String? previousTitle;
  final List<Widget> Function(BuildContext context, AppSettingsEntity settings)
  builder;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state is SettingsError) {
          context.showToast(state.message, kind: AppToastKind.error);
        }
      },
      builder: (context, state) {
        if (state is SettingsInitial) {
          context.read<SettingsBloc>().add(const LoadSettings());
        }
        final children = switch (state) {
          SettingsLoaded(:final settings) => builder(context, settings),
          SettingsError(:final message) => [
            ErrorView(
              message: message,
              onRetry: () =>
                  context.read<SettingsBloc>().add(const LoadSettings()),
            ),
          ],
          _ => const [
            Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        };
        return AppPage(
          title: title,
          previousTitle:
              previousTitle ??
              AppLocalizations.of(context)?.settings ??
              'Settings',
          actions: actions,
          children: children,
        );
      },
    );
  }
}
