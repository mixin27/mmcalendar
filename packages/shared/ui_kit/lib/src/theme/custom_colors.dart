import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// The ten colours a person can set by hand under Custom colours › Advanced.
enum CustomColorSlot {
  primary,
  onPrimary,
  secondary,
  onSecondary,
  tertiary,
  onTertiary,
  error,
  onError,
  surface,
  onSurface;

  Color of(ColorScheme scheme) => switch (this) {
    primary => scheme.primary,
    onPrimary => scheme.onPrimary,
    secondary => scheme.secondary,
    onSecondary => scheme.onSecondary,
    tertiary => scheme.tertiary,
    onTertiary => scheme.onTertiary,
    error => scheme.error,
    onError => scheme.onError,
    surface => scheme.surface,
    onSurface => scheme.onSurface,
  };

  ColorScheme apply(ColorScheme scheme, Color color) => switch (this) {
    primary => scheme.copyWith(primary: color),
    onPrimary => scheme.copyWith(onPrimary: color),
    secondary => scheme.copyWith(secondary: color),
    onSecondary => scheme.copyWith(onSecondary: color),
    tertiary => scheme.copyWith(tertiary: color),
    onTertiary => scheme.copyWith(onTertiary: color),
    error => scheme.copyWith(error: color),
    onError => scheme.copyWith(onError: color),
    surface => scheme.copyWith(surface: color),
    onSurface => scheme.copyWith(onSurface: color),
  };
}

/// A person's own colours: one accent ([seed]) that generates full light and
/// dark schemes, plus any slots they set by hand for each brightness.
@immutable
class CustomColors extends Equatable {
  const CustomColors({
    required this.seed,
    this.light = const {},
    this.dark = const {},
    this.basePreset = 'modern',
  });

  final Color seed;
  final Map<CustomColorSlot, Color> light;
  final Map<CustomColorSlot, Color> dark;

  /// The preset these colours started from; "Reset to preset" returns to it.
  final String basePreset;

  Map<CustomColorSlot, Color> overrides(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  ColorScheme scheme(Brightness brightness) {
    // Fidelity keeps the chosen hue's strength; the default tonal spot
    // variant would mute a vivid swatch.
    var scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    for (final MapEntry(:key, :value) in overrides(brightness).entries) {
      scheme = key.apply(scheme, value);
    }
    return scheme;
  }

  /// A new accent. Hand-set slots are cleared so the accent shows.
  CustomColors withSeed(Color seed) =>
      CustomColors(seed: seed, basePreset: basePreset);

  CustomColors withSlot(Brightness brightness, CustomColorSlot slot, Color c) {
    final dark = brightness == Brightness.dark;
    final next = {...overrides(brightness), slot: c};
    return CustomColors(
      seed: seed,
      light: dark ? light : next,
      dark: dark ? next : this.dark,
      basePreset: basePreset,
    );
  }

  Map<String, dynamic> toJson() => {
    'version': 2,
    'seed': seed.toARGB32(),
    'light': {for (final e in light.entries) e.key.name: e.value.toARGB32()},
    'dark': {for (final e in dark.entries) e.key.name: e.value.toARGB32()},
    'basePreset': basePreset,
  };

  /// Reads [toJson], or the older format: one brightness's ten slots, kept
  /// as hand-set colours with the primary as the accent.
  static CustomColors fromJson(Map<String, dynamic> json) {
    Map<CustomColorSlot, Color> slots(Object? map) => {
      if (map is Map)
        for (final slot in CustomColorSlot.values)
          if (map[slot.name] is int) slot: Color(map[slot.name] as int),
    };
    if (json['seed'] is int) {
      return CustomColors(
        seed: Color(json['seed'] as int),
        light: slots(json['light']),
        dark: slots(json['dark']),
        basePreset: json['basePreset'] as String? ?? 'modern',
      );
    }
    final legacy = slots(json);
    final dark = json['brightness'] == 'dark';
    return CustomColors(
      seed: legacy[CustomColorSlot.primary] ?? const Color(0xFF2F5BEA),
      light: dark ? const {} : legacy,
      dark: dark ? legacy : const {},
    );
  }

  @override
  List<Object?> get props => [seed, light, dark, basePreset];
}
