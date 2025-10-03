extension NumExtension on num {
  /// Convert to currency format
  String toCurrency({String symbol = r'\', int decimals = 2}) {
    return '$symbol${toStringAsFixed(decimals)}';
  }

  /// Convert to percentage format
  String toPercentage({int decimals = 0}) {
    return '${toStringAsFixed(decimals)}%';
  }

  /// Clamp between min and max
  num clampValue(num min, num max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }

  /// Check if number is between min and max (inclusive)
  bool isBetween(num min, num max) => this >= min && this <= max;

  /// Convert bytes to human readable format
  String toBytesReadable() {
    if (this < 1024) return '${toStringAsFixed(0)} B';
    if (this < 1024 * 1024) return '${(this / 1024).toStringAsFixed(1)} KB';
    if (this < 1024 * 1024 * 1024) {
      return '${(this / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
