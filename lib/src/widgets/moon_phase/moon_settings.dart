import 'dart:convert';

import 'package:flutter/material.dart';

class MoonSettings {
  const MoonSettings({
    this.size = 36,
    this.resolution = 96,
    this.lightColor = Colors.amber,
    this.earthshineColor = Colors.black87,
  });

  ///Decide the container size for the MoonWidget
  final double size;

  ///Resolution will be the moon radius.
  ///Large resolution needs more math operation makes widget heavy.
  ///Enter a small number if it is sufficient to mark it small,
  ///such as an icon or marker.
  final double resolution;

  ///Color of light side of moon
  final Color lightColor;

  ///Color of dark side of moon
  final Color earthshineColor;

  MoonSettings copyWith({
    double? size,
    double? resolution,
    Color? lightColor,
    Color? earthshineColor,
  }) {
    return MoonSettings(
      size: size ?? this.size,
      resolution: resolution ?? this.resolution,
      lightColor: lightColor ?? this.lightColor,
      earthshineColor: earthshineColor ?? this.earthshineColor,
    );
  }

  factory MoonSettings.defaultSettings() {
    return const MoonSettings(
        size: 36,
        resolution: 96,
        lightColor: Colors.amber,
        earthshineColor: Colors.black87);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'size': size,
      'resolution': resolution,
      'lightColor': lightColor.value,
      'earthshineColor': earthshineColor.value,
    };
  }

  factory MoonSettings.fromMap(Map<String, dynamic> map) {
    return MoonSettings(
      size: map['size'] as double,
      resolution: map['resolution'] as double,
      lightColor: Color(map['lightColor'] as int),
      earthshineColor: Color(map['earthshineColor'] as int),
    );
  }

  String toJson() => json.encode(toMap());

  factory MoonSettings.fromJson(String source) =>
      MoonSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'MoonSettings(size: $size, resolution: $resolution, lightColor: $lightColor, earthshineColor: $earthshineColor)';
  }

  @override
  bool operator ==(covariant MoonSettings other) {
    if (identical(this, other)) return true;

    return other.size == size &&
        other.resolution == resolution &&
        other.lightColor == lightColor &&
        other.earthshineColor == earthshineColor;
  }

  @override
  int get hashCode {
    return size.hashCode ^
        resolution.hashCode ^
        lightColor.hashCode ^
        earthshineColor.hashCode;
  }
}
