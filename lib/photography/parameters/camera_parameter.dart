/// Camera parameter model with full provenance tracking.
/// Every parameter knows where it came from and whether the user has locked it.
library;

import 'package:equatable/equatable.dart';

/// The origin of a camera parameter value.
enum ParameterSource {
  /// Set explicitly by the user via technical command (e.g., "ISO 200").
  userExplicit,
  /// Recommended by the AI photography reasoning engine.
  aiRecommendation,
  /// Derived from live scene analysis.
  sceneAnalysis,
  /// Selected automatically by the camera's auto mode.
  automatic,
  /// Device default / fallback.
  deviceDefault,
  /// Loaded from a saved preset.
  preset,
}

/// A single camera parameter value with provenance.
class ParameterValue<T> extends Equatable {
  const ParameterValue({
    required this.value,
    required this.source,
    this.confidence = 1.0,
    this.userLocked = false,
    this.explanation,
  });

  /// The actual parameter value.
  final T value;

  /// Where this value came from.
  final ParameterSource source;

  /// AI confidence (0.0 – 1.0). Always 1.0 for userExplicit.
  final double confidence;

  /// If true, no system component may override this value.
  /// Set when the user explicitly provides a technical value.
  final bool userLocked;

  /// Human-readable explanation of why this value was chosen.
  final String? explanation;

  /// Returns a copy with [userLocked] = true.
  ParameterValue<T> lock() => ParameterValue(
    value: value, source: source, confidence: confidence,
    userLocked: true, explanation: explanation,
  );

  /// Returns a copy with a new value (preserving lock status).
  ParameterValue<T> withValue(T newValue, {ParameterSource? source}) =>
      ParameterValue(
        value: newValue,
        source: source ?? this.source,
        confidence: confidence,
        userLocked: userLocked,
        explanation: explanation,
      );

  @override
  List<Object?> get props => [value, source, confidence, userLocked];

  @override
  String toString() =>
      'ParameterValue(value=$value, source=${source.name}, locked=$userLocked)';

  /// Convenience: creates a user-explicit locked parameter.
  factory ParameterValue.userSet(T value, {String? explanation}) =>
      ParameterValue(
        value: value,
        source: ParameterSource.userExplicit,
        confidence: 1.0,
        userLocked: true,
        explanation: explanation,
      );

  /// Convenience: creates an AI-recommended parameter.
  factory ParameterValue.aiSet(T value, {double confidence = 0.8, String? explanation}) =>
      ParameterValue(
        value: value,
        source: ParameterSource.aiRecommendation,
        confidence: confidence,
        userLocked: false,
        explanation: explanation,
      );

  /// Convenience: creates a device default.
  factory ParameterValue.deviceDefault(T value) => ParameterValue(
    value: value,
    source: ParameterSource.deviceDefault,
    confidence: 1.0,
    userLocked: false,
  );

  /// Convenience: creates a preset value.
  factory ParameterValue.fromPreset(T value, {String? explanation}) =>
      ParameterValue(
        value: value,
        source: ParameterSource.preset,
        confidence: 1.0,
        userLocked: false,
        explanation: explanation,
      );
}
