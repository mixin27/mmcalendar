extension ListExtension<T> on List<T> {
  /// Check if list is empty or null
  bool get isEmptyOrNull => isEmpty;

  /// Get first element or null
  T? get firstOrNull => isEmpty ? null : first;

  /// Get last element or null
  T? get lastOrNull => isEmpty ? null : last;

  /// Chunk list into smaller lists
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, (i + size).clamp(0, length)));
    }
    return chunks;
  }

  /// Group by a key
  Map<K, List<T>> groupBy<K>(K Function(T) keyFunction) {
    final map = <K, List<T>>{};
    for (final element in this) {
      final key = keyFunction(element);
      if (map.containsKey(key)) {
        map[key]!.add(element);
      } else {
        map[key] = [element];
      }
    }
    return map;
  }

  /// Get unique elements
  List<T> get unique => toSet().toList();

  /// Sum of numeric values
  num sum() {
    if (isEmpty) return 0;
    if (T == num || T == int || T == double) {
      return fold<num>(0, (sum, element) => sum + (element as num));
    }
    throw UnsupportedError('Cannot sum non-numeric list');
  }

  /// Average of numeric values
  double average() {
    if (isEmpty) return 0;
    return sum() / length;
  }
}
