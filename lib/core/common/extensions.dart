/// Common extension methods used throughout Kamera Pro.
library;

import 'dart:math' as math;

/// Extensions on [num].
extension NumExtensions on num {
  /// Clamps this value to [min]..[max].
  T clampTo<T extends num>(T min, T max) => math.max(min, math.min(max, this)) as T;

  /// Converts nanoseconds to a human-readable shutter speed string.
  /// e.g. 4000000 ns -> "1/250"
  String get asShutterString {
    final seconds = this / 1e9;
    if (seconds >= 1.0) return '${seconds.toStringAsFixed(1)}s';
    final denom = (1.0 / seconds).round();
    return '1/$denom';
  }
}

/// Extensions on [Duration].
extension DurationExtensions on Duration {
  /// Converts to nanoseconds as int.
  int get inNanoseconds => inMicroseconds * 1000;

  /// Converts to a human-readable shutter speed string.
  String get asShutterString => inNanoseconds.asShutterString;
}

/// Extensions on [String].
extension StringExtensions on String {
  /// Returns true if this string is not null and not empty.
  bool get isNotBlank => trim().isNotEmpty;

  /// Capitalizes the first letter.
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

/// Extensions on [List].
extension ListExtensions<T> on List<T> {
  /// Returns the first element matching [test], or null.
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
