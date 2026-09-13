/// Deterministic rule-based photography AI — offline, always available.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/photography_ai.dart';
import '../../photography/intent/photography_intent.dart';
import '../../core/logging/app_logger.dart';

class RuleBasedPhotographyAI implements PhotographyAI {
  const RuleBasedPhotographyAI();

  @override
  Future<PhotographyIntent> interpretCommand(
    String commandText,
    PhotographyContext context,
  ) async {
    final text = commandText.toLowerCase().trim();
    log.ai('RuleBasedAI: "$text"');

    double confidence = 0.5;
    final ob = _OverrideBuilder();

    // ── Technical overrides (highest confidence) ──
    final isoM = RegExp(r'iso\s*(?:to\s*)?(\d+)', caseSensitive: false).firstMatch(text);
    if (isoM != null) { ob.iso = int.tryParse(isoM.group(1)!); confidence = 0.95; }

    final shutM = RegExp(
      r'shutter(?:\s+speed)?\s*(?:to\s*)?(\d+\/\d+|\d+\.?\d*s?)',
      caseSensitive: false,
    ).firstMatch(text);
    if (shutM != null) { ob.shutterRaw = shutM.group(1); confidence = 0.95; }

    final wbM = RegExp(
      r'(?:white\s*balance|wb)\s*(?:to\s*)?(\d+)\s*k?|(?:(\d{4,5})\s*(?:kelvin|k))',
      caseSensitive: false,
    ).firstMatch(text);
    if (wbM != null) {
      ob.whiteBalanceK = int.tryParse(wbM.group(1) ?? wbM.group(2) ?? '');
      confidence = 0.95;
    }

    final zoomM = RegExp(
      r'(?:zoom\s*(?:to\s*)?|^)(\d+(?:\.\d+)?)\s*x|(?:(\d+(?:\.\d+)?)\s*x\s*zoom)',
      caseSensitive: false,
    ).firstMatch(text);
    if (zoomM != null) {
      ob.zoom = double.tryParse(zoomM.group(1) ?? zoomM.group(2) ?? '');
      confidence = 0.95;
    }

    FlashIntent? flash;
    if (_any(text, ['no flash', 'flash off', 'without flash'])) { flash = FlashIntent.off; confidence = 0.95; }
    else if (_any(text, ['flash on', 'use flash', 'with flash'])) { flash = FlashIntent.on; confidence = 0.95; }

    // ── Scene ──
    SceneType? scene;
    if (_any(text, ['portrait', 'selfie', 'face', 'person'])) { scene = SceneType.portrait; confidence = _hi(confidence, 0.9); }
    else if (_any(text, ['landscape', 'scenery', 'nature', 'outdoors'])) { scene = SceneType.landscape; confidence = _hi(confidence, 0.9); }
    else if (_any(text, ['night', 'dark', 'low light', 'nighttime'])) { scene = SceneType.night; confidence = _hi(confidence, 0.88); }
    else if (_any(text, ['sports', 'action', 'fast', 'running', 'moving'])) { scene = SceneType.sports; confidence = _hi(confidence, 0.85); }
    else if (_any(text, ['food', 'meal', 'dish', 'restaurant'])) { scene = SceneType.food; confidence = _hi(confidence, 0.9); }
    else if (_any(text, ['macro', 'close up', 'closeup', 'close-up', 'tiny'])) { scene = SceneType.macro; confidence = _hi(confidence, 0.88); }
    else if (_any(text, ['moon', 'lunar'])) { scene = SceneType.moon; confidence = _hi(confidence, 0.95); }
    else if (_any(text, ['document', 'paper', 'text', 'book', 'whiteboard'])) { scene = SceneType.document; confidence = _hi(confidence, 0.9); }
    else if (_any(text, ['product', 'object', 'item'])) { scene = SceneType.product; confidence = _hi(confidence, 0.85); }

    // ── Style ──
    StyleType? style;
    if (_any(text, ['cinematic', 'movie', 'film look', 'cinema'])) { style = StyleType.cinematic; confidence = _hi(confidence, 0.88); }
    else if (_any(text, ['vintage', 'retro', 'old', 'classic'])) { style = StyleType.vintage; confidence = _hi(confidence, 0.88); }
    else if (_any(text, ['black and white', 'black & white', 'bw', 'monochrome', 'grayscale', 'greyscale'])) { style = StyleType.blackAndWhite; confidence = _hi(confidence, 0.92); }
    else if (_any(text, ['moody', 'dramatic', 'dark mood'])) { style = StyleType.moody; confidence = _hi(confidence, 0.85); }
    else if (_any(text, ['bright', 'airy', 'luminous'])) { style = StyleType.bright; confidence = _hi(confidence, 0.8); }
    else if (_any(text, ['warm', 'golden', 'golden hour'])) { style = StyleType.warm; confidence = _hi(confidence, 0.85); }
    else if (_any(text, ['cool', 'cold', 'blue tone'])) { style = StyleType.cool; confidence = _hi(confidence, 0.8); }

    // ── Motion ──
    SubjectMotion? motion;
    if (_any(text, ['freeze', 'stop motion', 'moving fast'])) { motion = SubjectMotion.fastObject; confidence = _hi(confidence, 0.85); }
    else if (_any(text, ['running', 'sprint'])) { motion = SubjectMotion.running; confidence = _hi(confidence, 0.88); }
    else if (_any(text, ['car', 'vehicle', 'bike', 'motorcycle'])) { motion = SubjectMotion.vehicle; confidence = _hi(confidence, 0.85); }
    else if (_any(text, ['still', 'stationary', 'not moving'])) { motion = SubjectMotion.stationary; }

    // ── Lighting ──
    LightingIntent? lighting;
    if (_any(text, ['brighter', 'more light', 'increase exposure', 'overexpose'])) { lighting = LightingIntent.bright; confidence = _hi(confidence, 0.88); }
    else if (_any(text, ['darker', 'less light', 'underexpose'])) { lighting = LightingIntent.dark; confidence = _hi(confidence, 0.88); }
    else if (_any(text, ['warm light', 'warmer', 'warm color'])) { lighting = LightingIntent.warm; confidence = _hi(confidence, 0.85); }
    else if (_any(text, ['cool light', 'cooler', 'cool tone'])) { lighting = LightingIntent.cool; confidence = _hi(confidence, 0.8); }

    // ── Capture type ──
    CaptureType captureType = CaptureType.photo;
    if (_any(text, ['video', 'record', 'recording'])) captureType = CaptureType.video;
    else if (_any(text, ['burst', 'rapid', 'multiple shots'])) captureType = CaptureType.burst;

    final intent = PhotographyIntent(
      captureType: captureType,
      scene: scene,
      style: style,
      subjectMotion: motion,
      lightingIntent: lighting,
      flashIntent: flash,
      userOverrides: ob.build(),
      rawCommand: commandText,
      confidence: confidence,
    );
    log.ai('RuleBasedAI → $intent (confidence: $confidence)');
    return intent;
  }

  bool _any(String text, List<String> kw) => kw.any(text.contains);
  double _hi(double a, double b) => a > b ? a : b;
}

class _OverrideBuilder {
  int? iso;
  String? shutterRaw;
  int? whiteBalanceK;
  double? zoom;
  double? exposureCompensation;

  int? get shutterNs {
    if (shutterRaw == null) return null;
    final s = shutterRaw!.toLowerCase().replaceAll('s', '');
    if (s.contains('/')) {
      final parts = s.split('/');
      final d = double.tryParse(parts.last);
      if (d != null && d > 0) return (1e9 / d).round();
    }
    final d = double.tryParse(s);
    if (d != null) return d < 100 ? (1e9 / d).round() : (d * 1e9).round();
    return null;
  }

  UserTechnicalOverrides build() => UserTechnicalOverrides(
    iso: iso,
    shutterNs: shutterNs,
    whiteBalanceK: whiteBalanceK,
    zoomRatio: zoom,
    exposureCompensation: exposureCompensation,
  );
}

final ruleBasedAiProvider = Provider<PhotographyAI>(
  (_) => const RuleBasedPhotographyAI(),
);
