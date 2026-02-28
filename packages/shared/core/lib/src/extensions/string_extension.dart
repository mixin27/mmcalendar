extension StringExtension on String {
  /// Check if string is empty or null
  bool get isEmptyOrNull => isEmpty;

  /// Check if string is not empty
  bool get isNotEmpty => !isEmpty;

  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize each word
  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Remove all whitespace
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');

  /// Check if string is numeric
  bool get isNumeric => double.tryParse(this) != null;

  /// Check if string is a valid email
  bool get isValidEmail {
    final emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    return emailRegex.hasMatch(this);
  }

  /// Truncate string with ellipsis
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Parse to int with fallback
  int toIntOrZero() => int.tryParse(this) ?? 0;

  /// Parse to double with fallback
  double toDoubleOrZero() => double.tryParse(this) ?? 0.0;

  /// Parse to DateTime
  DateTime? toDateTime() => DateTime.tryParse(this);

  /// Check if string contains only letters
  bool get isAlpha => RegExp(r'^[a-zA-Z]+').hasMatch(this);

  /// Check if string contains only alphanumeric characters
  bool get isAlphanumeric => RegExp(r'^[a-zA-Z0-9]+').hasMatch(this);
}
