/// AI output JSON validator — security gate before PhotographyIntent creation.
library;

import '../../photography/intent/photography_intent.dart';
import '../../core/logging/app_logger.dart';
import '../../core/common/result.dart';

class AiOutputValidator {
  const AiOutputValidator();

  Result<PhotographyIntent, String> validate(
    Map<String, dynamic> json,
    String rawCommand,
  ) {
    try {
      return Result.ok(_parse(json, rawCommand));
    } catch (e, st) {
      log.ai('AI validation failed: $e', error: e, stackTrace: st);
      return Result.err('AI output could not be parsed: $e');
    }
  }

  PhotographyIntent _parse(Map<String, dynamic> json, String rawCommand) {
    return PhotographyIntent(
      captureType: _parseCaptureType(json['captureType']),
      scene: _parseEnum<SceneType>(json['scene'], SceneType.values),
      style: _parseEnum<StyleType>(json['style'], StyleType.values),
      subjectMotion: _parseEnum<SubjectMotion>(json['subjectMotion'], SubjectMotion.values),
      lightingIntent: _parseEnum<LightingIntent>(json['lightingIntent'], LightingIntent.values),
      composition: _parseEnum<CompositionHint>(json['composition'], CompositionHint.values),
      exposurePreference: _parseEnum<ExposurePreference>(
          json['exposurePreference'], ExposurePreference.values),
      focusPreference:
          _parseEnum<FocusPreference>(json['focusPreference'], FocusPreference.values),
      flashIntent: _parseEnum<FlashIntent>(json['flashIntent'], FlashIntent.values),
      userOverrides: _parseOverrides(json['userOverrides']),
      rawCommand: rawCommand,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.7,
      conflictWarnings: _parseStringList(json['conflictWarnings']),
    );
  }

  CaptureType _parseCaptureType(dynamic value) {
    if (value == null) return CaptureType.photo;
    final s = value.toString().toLowerCase().replaceAll('_', '');
    return switch (s) {
      'photo' || 'image' || 'picture' => CaptureType.photo,
      'video' || 'record' => CaptureType.video,
      'slowmotion' || 'slowmo' => CaptureType.slowMotion,
      'timelapse' => CaptureType.timelapse,
      'burst' => CaptureType.burst,
      _ => CaptureType.photo,
    };
  }

  T? _parseEnum<T extends Enum>(dynamic value, List<T> values) {
    if (value == null) return null;
    final s =
        value.toString().toLowerCase().replaceAll('_', '').replaceAll(' ', '');
    for (final v in values) {
      if (v.name.toLowerCase().replaceAll('_', '') == s) return v;
    }
    return null;
  }

  UserTechnicalOverrides _parseOverrides(dynamic raw) {
    if (raw == null || raw is! Map) return const UserTechnicalOverrides();
    final map = Map<String, dynamic>.from(raw as Map);
    return UserTechnicalOverrides(
      iso: _parseInt(map['iso']),
      shutterNs: _parseShutterNs(map['shutter']),
      whiteBalanceK: _parseInt(map['whiteBalanceK']),
      zoomRatio: _parseDouble(map['zoom']),
      exposureCompensation: _parseDouble(map['exposureCompensation']),
    );
  }

  int? _parseShutterNs(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    if (s.contains('/')) {
      final parts = s.split('/');
      if (parts.length == 2) {
        final denom = double.tryParse(parts[1]);
        if (denom != null && denom > 0) return (1e9 / denom).round();
      }
    }
    final d = double.tryParse(s);
    if (d != null) return d < 100000 ? (1e9 / d).round() : d.round();
    return null;
  }

  int? _parseInt(dynamic v) => v == null ? null : int.tryParse(v.toString());
  double? _parseDouble(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());
  List<String> _parseStringList(dynamic v) =>
      v is List ? v.map((e) => e.toString()).toList() : [];
}
