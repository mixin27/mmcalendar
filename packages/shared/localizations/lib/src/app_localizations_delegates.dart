import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show GlobalMaterialLocalizations;

import '../l10n/app_localizations.dart';

/// The delegates for a `MaterialApp` from package:material_ui: the app's
/// own strings, plus material_ui's Material, Cupertino and widgets
/// localizations (which have Myanmar).
///
/// [AppLocalizations.localizationsDelegates] alone is not enough: gen-l10n
/// still lists package:flutter's material localizations there, and a
/// material_ui app finds no Myanmar MaterialLocalizations without these.
const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates = [
  ...AppLocalizations.localizationsDelegates,
  ...GlobalMaterialLocalizations.delegates,
];
