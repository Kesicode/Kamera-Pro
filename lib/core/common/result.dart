/// A functional Result type for Kamera Pro operations.
/// Eliminates null-checks and uncaught exceptions across the codebase.
library;

/// Represents either a successful value [T] or an error [E].
sealed class Result<T, E> {
  const Result();

  /// Creates a successful result.
  factory Result.ok(T value) = Ok<T, E>;

  /// Creates a failure result.
  factory Result.err(E error) = Err<T, E>;

  /// Returns true if this is a success.
  bool get isOk => this is Ok<T, E>;

  /// Returns true if this is a failure.
  bool get isErr => this is Err<T, E>;

  /// Transforms the success value with [fn].
  Result<U, E> map<U>(U Function(T value) fn) => switch (this) {
    Ok(:final value) => Ok(fn(value)),
    Err(:final error) => Err(error),
  };

  /// Returns the success value or throws.
  T get valueOrThrow => switch (this) {
    Ok(:final value) => value,
    Err(:final error) => throw StateError('Result is Err: $error'),
  };

  /// Returns the success value or [defaultValue] on error.
  T valueOr(T defaultValue) => switch (this) {
    Ok(:final value) => value,
    Err() => defaultValue,
  };

  /// Executes [onOk] or [onErr] based on state.
  R fold<R>(R Function(T value) onOk, R Function(E error) onErr) =>
      switch (this) {
        Ok(:final value) => onOk(value),
        Err(:final error) => onErr(error),
      };
}

/// Success case.
final class Ok<T, E> extends Result<T, E> {
  const Ok(this.value);
  final T value;

  @override
  String toString() => 'Ok($value)';
}

/// Failure case.
final class Err<T, E> extends Result<T, E> {
  const Err(this.error);
  final E error;

  @override
  String toString() => 'Err($error)';
}
