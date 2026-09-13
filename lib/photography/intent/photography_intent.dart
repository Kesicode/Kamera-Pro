/// Strongly typed Photography Intent model.
/// This is the output of the AI/voice layer and the input to the reasoning engine.
/// The AI output MUST be parsed into this model — never passed raw to hardware.
library;

import 'package:equatable/equatable.dart';

// ────────────────────────────── Enum Taxonomy ──────────────────────────────

/// What kind of capture the user wants.
enum CaptureType {
  photo,
  video,
  slowMotion,
  timelapse,
  burst,
  raw,
}

/// The photographic scene context.
enum SceneType {
  portrait,
  landscape,
  night,
  food,
  architecture,
  macro,
  sports,
  lowLight,
  sunset,
  moon,
  stars,
  document,
  product,
  street,
  wildlife,
  general,
}

/// Photographic style / look the user wants.
enum StyleType {
  cinematic,
  vintage,
  film,
  blackAndWhite,
  natural,
  bright,
  moody,
  dramatic,
  soft,
  highContrast,
  cool,
  warm,
  none,
}

/// How the primary subject is expected to behave.
enum SubjectMotion {
  stationary,
  walking,
  running,
  vehicle,
  animal,
  fastObject,
  unknown,
}

/// The lighting mood the user wants.
enum LightingIntent {
  bright,
  dark,
  warm,
  cool,
  natural,
  dramatic,
  lowKey,
  highKey,
  auto,
}

/// Compositional hints from the user's description.
enum CompositionHint {
  closeUp,
  mediumShot,
  wideShot,
  centered,
  ruleOfThirds,
  overhead,
  lowAngle,
  highAngle,
  none,
}

/// The user's preference for exposure outcome.
enum ExposurePreference {
  balanced,
  bright,
  dark,
  faceExposed,
  highlightProtected,
  auto,
}

/// Focus target preference.
enum FocusPreference {
  subject,
  face,
  eyes,
  background,
  infinity,
  manual,
  auto,
}

/// Flash intent.
enum FlashIntent {
  off,
  on,
  auto,
  fill,
}

// ────────────────────────────── User Overrides ──────────────────────────────

/// Explicit technical overrides provided directly by the user.
/// These MUST be respected by the parameter engine and cannot be overridden by AI.
class UserTechnicalOverrides extends Equatable {
  const UserTechnicalOverrides({
    this.iso,
    this.shutterNs,
    this.whiteBalanceK,
    this.zoomRatio,
    this.exposureCompensation,
    this.focusDistanceDiopters,
  });

  final int? iso;
  final int? shutterNs;
  final int? whiteBalanceK;
  final double? zoomRatio;
  final double? exposureCompensation;
  final double? focusDistanceDiopters;

  bool get isEmpty =>
      iso == null &&
      shutterNs == null &&
      whiteBalanceK == null &&
      zoomRatio == null &&
      exposureCompensation == null &&
      focusDistanceDiopters == null;

  @override
  List<Object?> get props =>
      [iso, shutterNs, whiteBalanceK, zoomRatio, exposureCompensation, focusDistanceDiopters];
}

// ────────────────────────────── Photography Intent ──────────────────────────────

/// The structured intent parsed from a user's voice command.
///
/// This is the ONLY way AI output enters the parameter engine.
/// The AI must produce this object; raw AI text must never reach hardware.
class PhotographyIntent extends Equatable {
  const PhotographyIntent({
    this.captureType = CaptureType.photo,
    this.scene,
    this.style,
    this.subjectMotion,
    this.lightingIntent,
    this.composition,
    this.exposurePreference,
    this.focusPreference,
    this.flashIntent,
    this.userOverrides = const UserTechnicalOverrides(),
    this.rawCommand = '',
    this.confidence = 1.0,
    this.conflictWarnings = const [],
  });

  final CaptureType captureType;
  final SceneType? scene;
  final StyleType? style;
  final SubjectMotion? subjectMotion;
  final LightingIntent? lightingIntent;
  final CompositionHint? composition;
  final ExposurePreference? exposurePreference;
  final FocusPreference? focusPreference;
  final FlashIntent? flashIntent;
  final UserTechnicalOverrides userOverrides;
  final String rawCommand;
  final double confidence;
  final List<String> conflictWarnings;

  bool get hasConflicts => conflictWarnings.isNotEmpty;

  /// Human-readable summary for the UI.
  String get summary {
    final parts = <String>[];
    if (style != null && style != StyleType.none) parts.add(_styleLabel(style!));
    if (scene != null) parts.add(_sceneLabel(scene!));
    if (lightingIntent != null && lightingIntent != LightingIntent.auto) {
      parts.add(_lightingLabel(lightingIntent!));
    }
    return parts.isEmpty ? 'General Photo' : parts.join(' • ');
  }

  static String _styleLabel(StyleType s) => switch (s) {
    StyleType.cinematic => 'Cinematic',
    StyleType.vintage => 'Vintage',
    StyleType.film => 'Film',
    StyleType.blackAndWhite => 'B&W',
    StyleType.natural => 'Natural',
    StyleType.bright => 'Bright',
    StyleType.moody => 'Moody',
    StyleType.dramatic => 'Dramatic',
    StyleType.soft => 'Soft',
    StyleType.highContrast => 'High Contrast',
    StyleType.cool => 'Cool',
    StyleType.warm => 'Warm',
    StyleType.none => '',
  };

  static String _sceneLabel(SceneType s) => switch (s) {
    SceneType.portrait => 'Portrait',
    SceneType.landscape => 'Landscape',
    SceneType.night => 'Night',
    SceneType.food => 'Food',
    SceneType.architecture => 'Architecture',
    SceneType.macro => 'Macro',
    SceneType.sports => 'Sports',
    SceneType.lowLight => 'Low Light',
    SceneType.sunset => 'Sunset',
    SceneType.moon => 'Moon',
    SceneType.stars => 'Stars',
    SceneType.document => 'Document',
    SceneType.product => 'Product',
    SceneType.street => 'Street',
    SceneType.wildlife => 'Wildlife',
    SceneType.general => 'Photo',
  };

  static String _lightingLabel(LightingIntent l) => switch (l) {
    LightingIntent.bright => 'Bright',
    LightingIntent.dark => 'Dark',
    LightingIntent.warm => 'Warm',
    LightingIntent.cool => 'Cool',
    LightingIntent.natural => 'Natural',
    LightingIntent.dramatic => 'Dramatic',
    LightingIntent.lowKey => 'Low Key',
    LightingIntent.highKey => 'High Key',
    LightingIntent.auto => '',
  };

  @override
  List<Object?> get props => [
    captureType, scene, style, subjectMotion, lightingIntent,
    composition, exposurePreference, focusPreference, flashIntent,
    userOverrides, rawCommand, confidence,
  ];

  @override
  String toString() =>
      'PhotographyIntent(scene=${scene?.name}, style=${style?.name}, '
      'motion=${subjectMotion?.name}, lighting=${lightingIntent?.name})';

  PhotographyIntent copyWith({
    CaptureType? captureType,
    SceneType? scene,
    StyleType? style,
    SubjectMotion? subjectMotion,
    LightingIntent? lightingIntent,
    CompositionHint? composition,
    ExposurePreference? exposurePreference,
    FocusPreference? focusPreference,
    FlashIntent? flashIntent,
    UserTechnicalOverrides? userOverrides,
    String? rawCommand,
    double? confidence,
    List<String>? conflictWarnings,
  }) => PhotographyIntent(
    captureType: captureType ?? this.captureType,
    scene: scene ?? this.scene,
    style: style ?? this.style,
    subjectMotion: subjectMotion ?? this.subjectMotion,
    lightingIntent: lightingIntent ?? this.lightingIntent,
    composition: composition ?? this.composition,
    exposurePreference: exposurePreference ?? this.exposurePreference,
    focusPreference: focusPreference ?? this.focusPreference,
    flashIntent: flashIntent ?? this.flashIntent,
    userOverrides: userOverrides ?? this.userOverrides,
    rawCommand: rawCommand ?? this.rawCommand,
    confidence: confidence ?? this.confidence,
    conflictWarnings: conflictWarnings ?? this.conflictWarnings,
  );
}
