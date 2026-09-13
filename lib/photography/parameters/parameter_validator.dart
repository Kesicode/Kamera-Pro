/// Validates camera parameter plans against device capabilities.
/// This is the safety gate — nothing passes to hardware without going through here.
library;

import '../../camera/capabilities/camera_capabilities.dart';
import '../../core/logging/app_logger.dart';
import 'camera_parameter.dart';
import 'camera_parameter_plan.dart';

/// The result of validating a [CameraParameterPlan].
class ValidationResult {
  const ValidationResult({
    required this.validatedPlan,
    required this.rejected,
    required this.warnings,
  });

  final CameraParameterPlan validatedPlan;
  final List<RejectedParameter> rejected;
  final List<String> warnings;

  bool get hasRejections => rejected.isNotEmpty;
}

/// Validates a [CameraParameterPlan] against [CameraCapabilities].
///
/// Ensures that:
/// 1. No unsupported parameter is applied to the camera.
/// 2. All values are within the device's supported ranges.
/// 3. User-locked parameters are preserved and not silently changed.
/// 4. The AI cannot bypass hardware limits.
class ParameterValidator {
  const ParameterValidator();

  /// Validates [plan] against [capabilities].
  ValidationResult validate(
    CameraParameterPlan plan,
    CameraCapabilities capabilities,
  ) {
    final rejected = <RejectedParameter>[];
    final warnings = <String>[];
    var validatedPlan = plan;

    // ── ISO ──
    if (plan.iso != null) {
      final isoResult = _validateIso(plan.iso!, capabilities);
      if (isoResult != null) {
        if (plan.iso!.userLocked) {
          warnings.add(isoResult.userMessage ?? isoResult.reason);
          log.warning(
              'ISO: user override ${plan.iso!.value} outside range '
              '${capabilities.isoRange} — preserving with warning');
        } else {
          rejected.add(isoResult);
          validatedPlan = validatedPlan.copyWith(iso: null);
        }
      }
    }

    // ── Shutter ──
    if (plan.shutterNs != null) {
      final shutterResult = _validateShutter(plan.shutterNs!, capabilities);
      if (shutterResult != null) {
        if (plan.shutterNs!.userLocked) {
          warnings.add(shutterResult.userMessage ?? shutterResult.reason);
          log.warning('Shutter: user override outside range — preserving with warning');
        } else {
          rejected.add(shutterResult);
          validatedPlan = validatedPlan.copyWith(shutterNs: null);
        }
      }
    }

    // ── White Balance ──
    if (plan.whiteBalanceK != null) {
      final wbResult = _validateWhiteBalance(plan.whiteBalanceK!, capabilities);
      if (wbResult != null) {
        rejected.add(wbResult);
        validatedPlan = validatedPlan.copyWith(whiteBalanceK: null);
      }
    }

    // ── Zoom ──
    if (plan.zoom != null) {
      final zoomResult = _validateZoom(plan.zoom!, capabilities);
      if (zoomResult != null) {
        // Clamp zoom to max instead of rejecting
        final clampedZoom =
            capabilities.zoomRange?.clamp(plan.zoom!.value) ?? plan.zoom!.value;
        validatedPlan = validatedPlan.copyWith(
          zoom: plan.zoom!.withValue(clampedZoom),
        );
        warnings.add('Zoom clamped to ${clampedZoom.toStringAsFixed(1)}x '
            '(max: ${capabilities.maxZoom}x)');
      }
    }

    // ── AF Mode ──
    if (plan.afMode != null) {
      if (!capabilities.supportedAfModes.contains(plan.afMode!.value)) {
        rejected.add(RejectedParameter(
          parameterName: 'af_mode',
          requestedValue: plan.afMode!.value.name,
          reason: 'AF mode ${plan.afMode!.value.name} not supported',
          userMessage: 'Auto-focus mode not supported — using default.',
        ));
        validatedPlan = validatedPlan.copyWith(afMode: null);
      }
    }

    // ── Flash ──
    if (plan.flash != null && plan.flash!.value && !capabilities.supportsFlash) {
      rejected.add(const RejectedParameter(
        parameterName: 'flash',
        requestedValue: true,
        reason: 'No flash hardware available',
        userMessage: 'This camera does not have a flash.',
      ));
      validatedPlan = validatedPlan.copyWith(flash: null);
    }

    // ── Exposure Compensation ──
    if (plan.exposureCompensation != null &&
        capabilities.exposureCompensationRange != null) {
      final ev = plan.exposureCompensation!.value;
      final range = capabilities.exposureCompensationRange!;
      if (!range.contains(ev)) {
        final clamped = range.clamp(ev);
        validatedPlan = validatedPlan.copyWith(
          exposureCompensation: plan.exposureCompensation!.withValue(clamped),
        );
        warnings.add('EV clamped to ${clamped.toStringAsFixed(1)} '
            '(range: ${range.min} to ${range.max})');
      }
    }

    // ── Manual AE check ──
    final hasManualIso = validatedPlan.iso != null;
    final hasManualShutter = validatedPlan.shutterNs != null;
    if ((hasManualIso || hasManualShutter) &&
        !capabilities.supportsManualIso &&
        !capabilities.supportsManualShutter) {
      warnings.add(
        'This camera does not support manual exposure. Using auto exposure.',
      );
    }

    // Log
    for (final r in rejected) {
      log.params('REJECTED: ${r.parameterName} = ${r.requestedValue} — ${r.reason}');
    }
    for (final w in warnings) {
      log.params('WARNING: $w');
    }

    return ValidationResult(
      validatedPlan: validatedPlan.copyWith(
        rejectedParameters: rejected,
        warnings: warnings,
      ),
      rejected: rejected,
      warnings: warnings,
    );
  }

  // ──────────────────────── Private validators ────────────────────────

  RejectedParameter? _validateIso(
    ParameterValue<int> iso,
    CameraCapabilities capabilities,
  ) {
    if (!capabilities.supportsManualIso) {
      return RejectedParameter(
        parameterName: 'iso',
        requestedValue: iso.value,
        reason: 'Manual ISO not supported on this camera',
        userMessage:
            'This camera does not support manual ISO. Using auto exposure.',
      );
    }
    final range = capabilities.isoRange;
    if (range != null && !range.contains(iso.value)) {
      final clamped = range.clamp(iso.value);
      return RejectedParameter(
        parameterName: 'iso',
        requestedValue: iso.value,
        reason: 'ISO ${iso.value} outside supported range $range',
        closestSupported: clamped,
        userMessage:
            'ISO ${iso.value} is not supported. Closest supported: ISO $clamped.',
      );
    }
    return null;
  }

  RejectedParameter? _validateShutter(
    ParameterValue<int> shutterNs,
    CameraCapabilities capabilities,
  ) {
    if (!capabilities.supportsManualShutter) {
      return RejectedParameter(
        parameterName: 'shutter',
        requestedValue: shutterNs.value,
        reason: 'Manual shutter not supported on this camera',
        userMessage:
            'This camera does not expose manual shutter control. '
            'I can still optimize the exposure automatically.',
      );
    }
    final range = capabilities.shutterRangeNs;
    if (range != null && !range.contains(shutterNs.value)) {
      return RejectedParameter(
        parameterName: 'shutter',
        requestedValue: shutterNs.value,
        reason: 'Shutter outside supported range',
        closestSupported: range.clamp(shutterNs.value),
        userMessage:
            'Shutter speed not in supported range '
            '(${_nsLabel(range.min)} – ${_nsLabel(range.max)}).',
      );
    }
    return null;
  }

  RejectedParameter? _validateWhiteBalance(
    ParameterValue<int> wb,
    CameraCapabilities capabilities,
  ) {
    if (!capabilities.supportsManualWhiteBalance) {
      return RejectedParameter(
        parameterName: 'white_balance',
        requestedValue: wb.value,
        reason: 'Manual white balance not supported',
        userMessage: 'Manual white balance is not supported on this camera.',
      );
    }
    final range = capabilities.whiteBalanceRange;
    if (range != null && !range.contains(wb.value)) {
      return RejectedParameter(
        parameterName: 'white_balance',
        requestedValue: wb.value,
        reason: 'WB ${wb.value}K outside range $range',
        closestSupported: range.clamp(wb.value),
        userMessage:
            'White balance ${wb.value}K is outside the supported range.',
      );
    }
    return null;
  }

  RejectedParameter? _validateZoom(
    ParameterValue<double> zoom,
    CameraCapabilities capabilities,
  ) {
    if (!capabilities.supportsZoom) {
      return RejectedParameter(
        parameterName: 'zoom',
        requestedValue: zoom.value,
        reason: 'Zoom not supported',
        userMessage: 'Zoom is not available on this camera.',
      );
    }
    final range = capabilities.zoomRange;
    if (range != null && !range.contains(zoom.value)) {
      return RejectedParameter(
        parameterName: 'zoom',
        requestedValue: zoom.value,
        reason: 'Zoom ${zoom.value}x outside range $range',
        closestSupported: range.clamp(zoom.value),
        userMessage:
            'Zoom ${zoom.value}x not supported. '
            'Using ${range.clamp(zoom.value).toStringAsFixed(1)}x.',
      );
    }
    return null;
  }

  String _nsLabel(int ns) {
    final secs = ns / 1e9;
    if (secs >= 1.0) return '${secs.toStringAsFixed(1)}s';
    return '1/${(1.0 / secs).round()}';
  }
}
