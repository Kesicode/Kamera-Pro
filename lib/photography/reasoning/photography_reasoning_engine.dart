/// The Photography Reasoning Engine.
///
/// Translates a [PhotographyIntent] into a [CameraParameterPlan]
/// by applying scene-specific photographic knowledge and device constraints.
///
/// This is where photography expertise lives, separate from both AI and hardware.
library;

import '../../camera/capabilities/camera_capabilities.dart';
import '../intent/photography_intent.dart';
import '../parameters/camera_parameter.dart';
import '../parameters/camera_parameter_plan.dart';
import '../../core/logging/app_logger.dart';

/// Input context for the reasoning engine.
class ReasoningContext {
  const ReasoningContext({
    required this.capabilities,
    this.estimatedSceneLux,
    this.isSubjectDetected = false,
    this.isFaceDetected = false,
    this.estimatedMotionLevel = 0.0,
  });

  final CameraCapabilities capabilities;

  /// Estimated scene brightness in lux. null = unknown.
  final double? estimatedSceneLux;
  final bool isSubjectDetected;
  final bool isFaceDetected;

  /// 0.0 = stationary, 1.0 = fast motion.
  final double estimatedMotionLevel;

  bool get isLowLight => estimatedSceneLux != null && estimatedSceneLux! < 200;
  bool get isBrightLight => estimatedSceneLux != null && estimatedSceneLux! > 2000;
}

/// Translates photography intent into a camera parameter plan.
class PhotographyReasoningEngine {
  const PhotographyReasoningEngine();

  /// Generates a [CameraParameterPlan] from [intent] and [context].
  CameraParameterPlan reason(
    PhotographyIntent intent,
    ReasoningContext context,
  ) {
    log.ai('PhotographyReasoningEngine: reasoning for ${intent.summary}');

    final caps = context.capabilities;

    // 1. Start with scene-based strategy
    var plan = _reasonForScene(intent, context);

    // 2. Apply style modifications on top
    if (intent.style != null) {
      plan = _applyStyle(intent.style!, plan, caps, context);
    }

    // 3. Apply lighting modifications
    if (intent.lightingIntent != null) {
      plan = _applyLighting(intent.lightingIntent!, plan, caps);
    }

    // 4. Apply motion considerations
    if (intent.subjectMotion != null) {
      plan = _applyMotion(intent.subjectMotion!, plan, caps, context);
    }

    // 5. Apply explicit user overrides LAST (highest priority after safety)
    plan = _applyUserOverrides(intent.userOverrides, plan, caps);

    // 6. Generate educational explanation
    final explanation = _buildExplanation(intent, plan, caps);
    plan = plan.copyWith(educationalExplanation: explanation);

    log.ai('Reasoning complete: ${plan.parameterSummary}');
    return plan;
  }

  // ──────────────────────── Scene Strategies ────────────────────────

  CameraParameterPlan _reasonForScene(
    PhotographyIntent intent,
    ReasoningContext context,
  ) {
    final caps = context.capabilities;
    return switch (intent.scene) {
      SceneType.portrait => _portraitStrategy(intent, context, caps),
      SceneType.landscape => _landscapeStrategy(intent, context, caps),
      SceneType.night || SceneType.lowLight => _nightStrategy(intent, context, caps),
      SceneType.sports => _sportsStrategy(intent, context, caps),
      SceneType.macro => _macroStrategy(intent, context, caps),
      SceneType.food => _foodStrategy(intent, context, caps),
      SceneType.moon => _moonStrategy(intent, context, caps),
      SceneType.stars => _nightStrategy(intent, context, caps),
      SceneType.document => _documentStrategy(intent, context, caps),
      _ => _generalStrategy(intent, context, caps),
    };
  }

  CameraParameterPlan _portraitStrategy(
    PhotographyIntent intent,
    ReasoningContext context,
    CameraCapabilities caps,
  ) {
    return CameraParameterPlan(
      iso: caps.supportsManualIso && !context.isLowLight
          ? ParameterValue.aiSet(100, explanation: 'Low ISO keeps skin tones clean.')
          : null,
      shutterNs: caps.supportsManualShutter
          ? ParameterValue.aiSet(
              _shutterFraction(250),
              explanation: 'Fast enough to freeze small movements.',
            )
          : null,
      whiteBalanceK: caps.supportsManualWhiteBalance
          ? ParameterValue.aiSet(
              5500,
              explanation: 'Warm daylight white balance flatters skin.',
            )
          : null,
      zoom: caps.supportsZoom
          ? ParameterValue.aiSet(
              _clampZoom(2.0, caps),
              explanation: '2x zoom creates flattering portrait compression.',
            )
          : null,
      afMode: ParameterValue.aiSet(
        caps.supportedAfModes.contains(AfMode.continuous)
            ? AfMode.continuous
            : AfMode.single,
        explanation: 'Continuous focus tracks the subject face.',
      ),
      flash: ParameterValue.aiSet(false, explanation: 'Natural light for portraits.'),
      useAutoExposure: !caps.supportsManualIso,
      useAutoWhiteBalance: !caps.supportsManualWhiteBalance,
    );
  }

  CameraParameterPlan _landscapeStrategy(
    PhotographyIntent intent,
    ReasoningContext context,
    CameraCapabilities caps,
  ) {
    return CameraParameterPlan(
      iso: caps.supportsManualIso
          ? ParameterValue.aiSet(50,
              explanation: 'Lowest ISO for maximum sharpness.')
          : null,
      shutterNs: caps.supportsManualShutter
          ? ParameterValue.aiSet(
              _shutterFraction(125),
              explanation: 'Balanced shutter for a stable scene.',
            )
          : null,
      whiteBalanceK: caps.supportsManualWhiteBalance
          ? ParameterValue.aiSet(5600,
              explanation: 'Daylight white balance for accurate colors.')
          : null,
      zoom: caps.supportsZoom
          ? ParameterValue.aiSet(_clampZoom(1.0, caps),
              explanation: 'Wide angle captures the full scene.')
          : null,
      afMode: ParameterValue.aiSet(
        caps.supportedAfModes.contains(AfMode.continuous)
            ? AfMode.continuous
            : AfMode.single,
      ),
      flash: ParameterValue.aiSet(false),
      useAutoExposure: !caps.supportsManualIso,
      useAutoWhiteBalance: !caps.supportsManualWhiteBalance,
    );
  }

  CameraParameterPlan _nightStrategy(
    PhotographyIntent intent,
    ReasoningContext context,
    CameraCapabilities caps,
  ) {
    final maxIso = caps.isoRange?.max ?? 3200;
    final recommendedIso = (maxIso ~/ 2).clamp(800, maxIso);
    return CameraParameterPlan(
      iso: caps.supportsManualIso
          ? ParameterValue.aiSet(recommendedIso,
              explanation: 'Higher ISO needed for low-light capture.')
          : null,
      shutterNs: caps.supportsManualShutter
          ? ParameterValue.aiSet(
              _shutterFraction(30),
              explanation: 'Slower shutter lets in more light. Hold steady.',
            )
          : null,
      whiteBalanceK: caps.supportsManualWhiteBalance
          ? ParameterValue.aiSet(3200,
              explanation: 'Cooler WB corrects artificial lighting.')
          : null,
      zoom: caps.supportsZoom
          ? ParameterValue.aiSet(_clampZoom(1.0, caps))
          : null,
      afMode: ParameterValue.aiSet(
        caps.supportedAfModes.contains(AfMode.single)
            ? AfMode.single
            : AfMode.fixed,
        explanation: 'Single AF locks focus in low light.',
      ),
      flash: ParameterValue.aiSet(false,
          explanation: 'Avoid flash washing out night scenes.'),
      useAutoExposure: !caps.supportsManualIso,
      useAutoWhiteBalance: !caps.supportsManualWhiteBalance,
    );
  }

  CameraParameterPlan _sportsStrategy(
    PhotographyIntent intent,
    ReasoningContext context,
    CameraCapabilities caps,
  ) {
    return CameraParameterPlan(
      iso: caps.supportsManualIso
          ? ParameterValue.aiSet(
              context.isBrightLight ? 200 : 400,
              explanation: 'Moderate ISO balances noise and shutter speed.',
            )
          : null,
      shutterNs: caps.supportsManualShutter
          ? ParameterValue.aiSet(
              _shutterFraction(1000),
              explanation: 'Fast shutter freezes motion completely.',
            )
          : null,
      afMode: ParameterValue.aiSet(
        caps.supportedAfModes.contains(AfMode.continuous)
            ? AfMode.continuous
            : AfMode.single,
        explanation: 'Continuous AF tracks the moving subject.',
      ),
      flash: ParameterValue.aiSet(false),
      useAutoExposure: !caps.supportsManualIso,
      useAutoWhiteBalance: true,
    );
  }

  CameraParameterPlan _macroStrategy(
    PhotographyIntent intent,
    ReasoningContext context,
    CameraCapabilities caps,
  ) {
    return CameraParameterPlan(
      iso: caps.supportsManualIso
          ? ParameterValue.aiSet(100,
              explanation: 'Low ISO for fine macro detail.')
          : null,
      shutterNs: caps.supportsManualShutter
          ? ParameterValue.aiSet(_shutterFraction(200))
          : null,
      zoom: caps.supportsZoom
          ? ParameterValue.aiSet(_clampZoom(1.0, caps))
          : null,
      afMode: ParameterValue.aiSet(
        caps.supportedAfModes.contains(AfMode.single)
            ? AfMode.single
            : AfMode.fixed,
        explanation: 'Single AF for precise focus control.',
      ),
      flash: ParameterValue.aiSet(false,
          explanation: 'Avoid harsh shadow in macro.'),
      useAutoExposure: !caps.supportsManualIso,
      useAutoWhiteBalance: true,
    );
  }

  CameraParameterPlan _foodStrategy(
    PhotographyIntent intent,
    ReasoningContext context,
    CameraCapabilities caps,
  ) {
    return CameraParameterPlan(
      iso: caps.supportsManualIso
          ? ParameterValue.aiSet(100,
              explanation: 'Low ISO for vivid food colors.')
          : null,
      whiteBalanceK: caps.supportsManualWhiteBalance
          ? ParameterValue.aiSet(5200,
              explanation: 'Accurate WB preserves food colors.')
          : null,
      afMode: ParameterValue.aiSet(
        caps.supportedAfModes.contains(AfMode.single)
            ? AfMode.single
            : AfMode.fixed,
      ),
      flash: ParameterValue.aiSet(false,
          explanation: 'Avoid glossy reflections on food.'),
      useAutoExposure: !caps.supportsManualIso,
      useAutoWhiteBalance: !caps.supportsManualWhiteBalance,
    );
  }

  CameraParameterPlan _moonStrategy(
    PhotographyIntent intent,
    ReasoningContext context,
    CameraCapabilities caps,
  ) {
    return CameraParameterPlan(
      iso: caps.supportsManualIso
          ? ParameterValue.aiSet(100,
              explanation: 'Moon is bright — low ISO prevents overexposure.')
          : null,
      shutterNs: caps.supportsManualShutter
          ? ParameterValue.aiSet(
              _shutterFraction(500),
              explanation: 'Fast shutter for the bright moon surface.',
            )
          : null,
      zoom: caps.supportsZoom
          ? ParameterValue.aiSet(
              _clampZoom(caps.maxZoom, caps),
              explanation: 'Maximum zoom to frame the moon.',
            )
          : null,
      afMode: ParameterValue.aiSet(
        caps.supportedAfModes.contains(AfMode.single)
            ? AfMode.single
            : AfMode.fixed,
      ),
      flash: ParameterValue.aiSet(false),
      useAutoExposure: !caps.supportsManualIso,
      useAutoWhiteBalance: true,
    );
  }

  CameraParameterPlan _documentStrategy(
    PhotographyIntent intent,
    ReasoningContext context,
    CameraCapabilities caps,
  ) {
    return CameraParameterPlan(
      iso: caps.supportsManualIso
          ? ParameterValue.aiSet(100)
          : null,
      afMode: ParameterValue.aiSet(
        caps.supportedAfModes.contains(AfMode.single)
            ? AfMode.single
            : AfMode.fixed,
      ),
      flash: ParameterValue.aiSet(false),
      useAutoExposure: true,
      useAutoWhiteBalance: true,
    );
  }

  CameraParameterPlan _generalStrategy(
    PhotographyIntent intent,
    ReasoningContext context,
    CameraCapabilities caps,
  ) {
    return CameraParameterPlan(
      afMode: ParameterValue.aiSet(
        caps.supportedAfModes.contains(AfMode.continuous)
            ? AfMode.continuous
            : AfMode.single,
      ),
      flash: ParameterValue.aiSet(false),
      useAutoExposure: true,
      useAutoWhiteBalance: true,
    );
  }

  // ──────────────────────── Style Modifiers ────────────────────────

  CameraParameterPlan _applyStyle(
    StyleType style,
    CameraParameterPlan plan,
    CameraCapabilities caps,
    ReasoningContext context,
  ) {
    switch (style) {
      case StyleType.cinematic:
        return plan.copyWith(
          whiteBalanceK: caps.supportsManualWhiteBalance && plan.whiteBalanceK == null
              ? ParameterValue.aiSet(5600,
                  explanation: 'Warm cinematic color temp.')
              : plan.whiteBalanceK,
          exposureCompensation: plan.exposureCompensation ??
              ParameterValue.aiSet(-0.3,
                  explanation: 'Slight underexposure for drama.'),
          zoom: plan.zoom ??
              (caps.supportsZoom
                  ? ParameterValue.aiSet(_clampZoom(2.0, caps),
                      explanation: 'Cinematic framing.')
                  : null),
        );

      case StyleType.warm:
        return plan.copyWith(
          whiteBalanceK: caps.supportsManualWhiteBalance
              ? ParameterValue.aiSet(6500,
                  explanation: 'Warm white balance for golden tones.')
              : plan.whiteBalanceK,
        );

      case StyleType.cool:
        return plan.copyWith(
          whiteBalanceK: caps.supportsManualWhiteBalance
              ? ParameterValue.aiSet(4000,
                  explanation: 'Cool white balance for blue tones.')
              : plan.whiteBalanceK,
        );

      case StyleType.vintage || StyleType.film:
        return plan.copyWith(
          whiteBalanceK: caps.supportsManualWhiteBalance
              ? ParameterValue.aiSet(5000,
                  explanation: 'Neutral-warm for film look.')
              : plan.whiteBalanceK,
          iso: plan.iso ??
              (caps.supportsManualIso
                  ? ParameterValue.aiSet(200,
                      explanation: 'Slight grain for film character.')
                  : null),
        );

      case StyleType.bright:
        return plan.copyWith(
          exposureCompensation: ParameterValue.aiSet(
            0.7,
            explanation: 'Positive EV for a bright airy look.',
          ),
        );

      case StyleType.moody || StyleType.dramatic:
        return plan.copyWith(
          exposureCompensation: ParameterValue.aiSet(
            -0.7,
            explanation: 'Negative EV for moody, dramatic shadows.',
          ),
        );

      default:
        return plan;
    }
  }

  // ──────────────────────── Lighting Modifiers ────────────────────────

  CameraParameterPlan _applyLighting(
    LightingIntent lighting,
    CameraParameterPlan plan,
    CameraCapabilities caps,
  ) {
    return switch (lighting) {
      LightingIntent.bright => plan.copyWith(
          exposureCompensation: ParameterValue.aiSet(0.7),
        ),
      LightingIntent.dark => plan.copyWith(
          exposureCompensation: ParameterValue.aiSet(-0.7),
        ),
      LightingIntent.warm => plan.copyWith(
          whiteBalanceK: caps.supportsManualWhiteBalance
              ? ParameterValue.aiSet(6500)
              : plan.whiteBalanceK,
        ),
      LightingIntent.cool => plan.copyWith(
          whiteBalanceK: caps.supportsManualWhiteBalance
              ? ParameterValue.aiSet(4000)
              : plan.whiteBalanceK,
        ),
      _ => plan,
    };
  }

  // ──────────────────────── Motion Modifiers ────────────────────────

  CameraParameterPlan _applyMotion(
    SubjectMotion motion,
    CameraParameterPlan plan,
    CameraCapabilities caps,
    ReasoningContext context,
  ) {
    if (motion == SubjectMotion.stationary || motion == SubjectMotion.unknown) {
      return plan;
    }

    final fastShutterNs = switch (motion) {
      SubjectMotion.running ||
      SubjectMotion.vehicle ||
      SubjectMotion.fastObject =>
        _shutterFraction(1000),
      SubjectMotion.walking || SubjectMotion.animal => _shutterFraction(500),
      _ => null,
    };

    if (fastShutterNs == null) return plan;

    return plan.copyWith(
      shutterNs: caps.supportsManualShutter
          ? ParameterValue.aiSet(
              fastShutterNs,
              explanation: 'Fast shutter to freeze the moving subject.',
            )
          : plan.shutterNs,
      afMode: ParameterValue.aiSet(
        caps.supportedAfModes.contains(AfMode.continuous)
            ? AfMode.continuous
            : AfMode.single,
        explanation: 'Continuous AF tracks the moving subject.',
      ),
    );
  }

  // ──────────────────────── User Overrides ────────────────────────

  /// Applies explicit user technical overrides.
  /// These MUST NOT be overridden by any AI or scene logic.
  CameraParameterPlan _applyUserOverrides(
    UserTechnicalOverrides overrides,
    CameraParameterPlan plan,
    CameraCapabilities caps,
  ) {
    if (overrides.isEmpty) return plan;
    return plan.copyWith(
      iso: overrides.iso != null
          ? ParameterValue.userSet(overrides.iso!,
              explanation: 'Set by you explicitly.')
          : plan.iso,
      shutterNs: overrides.shutterNs != null
          ? ParameterValue.userSet(overrides.shutterNs!,
              explanation: 'Set by you explicitly.')
          : plan.shutterNs,
      whiteBalanceK: overrides.whiteBalanceK != null
          ? ParameterValue.userSet(overrides.whiteBalanceK!,
              explanation: 'Set by you explicitly.')
          : plan.whiteBalanceK,
      zoom: overrides.zoomRatio != null
          ? ParameterValue.userSet(overrides.zoomRatio!,
              explanation: 'Set by you explicitly.')
          : plan.zoom,
      exposureCompensation: overrides.exposureCompensation != null
          ? ParameterValue.userSet(overrides.exposureCompensation!,
              explanation: 'Set by you.')
          : plan.exposureCompensation,
    );
  }

  // ──────────────────────── Education ────────────────────────

  String _buildExplanation(
    PhotographyIntent intent,
    CameraParameterPlan plan,
    CameraCapabilities caps,
  ) {
    final parts = <String>[];
    if (plan.iso?.explanation != null) {
      parts.add('• ISO ${plan.iso!.value}: ${plan.iso!.explanation}');
    }
    if (plan.shutterNs?.explanation != null) {
      final label = _nsToLabel(plan.shutterNs!.value);
      parts.add('• $label: ${plan.shutterNs!.explanation}');
    }
    if (plan.whiteBalanceK?.explanation != null) {
      parts.add('• ${plan.whiteBalanceK!.value}K: ${plan.whiteBalanceK!.explanation}');
    }
    if (plan.zoom?.explanation != null) {
      parts.add(
          '• ${plan.zoom!.value.toStringAsFixed(1)}x zoom: ${plan.zoom!.explanation}');
    }
    if (plan.afMode?.explanation != null) {
      parts.add('• Focus: ${plan.afMode!.explanation}');
    }
    return parts.join('\n');
  }

  // ──────────────────────── Helpers ────────────────────────

  int _shutterFraction(int denominator) => (1e9 / denominator).round();

  double _clampZoom(double requested, CameraCapabilities caps) {
    if (!caps.supportsZoom || caps.zoomRange == null) return 1.0;
    return caps.zoomRange!.clamp(requested);
  }

  String _nsToLabel(int ns) {
    final secs = ns / 1e9;
    if (secs >= 1.0) return '${secs.toStringAsFixed(1)}s';
    return '1/${(1.0 / secs).round()}';
  }
}
