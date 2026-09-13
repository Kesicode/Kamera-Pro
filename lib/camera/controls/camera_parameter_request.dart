/// Typed camera parameter requests that go from the HAL to hardware.
/// These are distinct from PhotographyIntent — they are low-level hardware values.
library;

import '../capabilities/camera_capabilities.dart';

/// A single camera parameter change request.
sealed class CameraParameterRequest {
  const CameraParameterRequest();

  /// Human-readable name of this parameter (for logging).
  String get parameterName;
}

/// ISO value request.
final class IsoRequest extends CameraParameterRequest {
  const IsoRequest(this.iso);
  final int iso;

  @override
  String get parameterName => 'iso';

  @override
  String toString() => 'IsoRequest(iso=$iso)';
}

/// Shutter speed request in nanoseconds.
final class ShutterRequest extends CameraParameterRequest {
  const ShutterRequest(this.shutterNs);
  final int shutterNs;

  @override
  String get parameterName => 'shutter';

  @override
  String toString() => 'ShutterRequest(shutterNs=$shutterNs)';
}

/// White balance request in Kelvin.
final class WhiteBalanceRequest extends CameraParameterRequest {
  const WhiteBalanceRequest(this.kelvin);
  final int kelvin;

  @override
  String get parameterName => 'white_balance';

  @override
  String toString() => 'WhiteBalanceRequest(kelvin=$kelvin)';
}

/// Exposure compensation request in EV steps.
final class ExposureCompensationRequest extends CameraParameterRequest {
  const ExposureCompensationRequest(this.ev);
  final double ev;

  @override
  String get parameterName => 'exposure_compensation';

  @override
  String toString() => 'ExposureCompensationRequest(ev=$ev)';
}

/// Zoom ratio request.
final class ZoomRequest extends CameraParameterRequest {
  const ZoomRequest(this.ratio);
  final double ratio;

  @override
  String get parameterName => 'zoom';

  @override
  String toString() => 'ZoomRequest(ratio=$ratio)';
}

/// Auto-focus mode request.
final class AfModeRequest extends CameraParameterRequest {
  const AfModeRequest(this.mode);
  final AfMode mode;

  @override
  String get parameterName => 'af_mode';

  @override
  String toString() => 'AfModeRequest(mode=${mode.name})';
}

/// Flash toggle request.
final class FlashRequest extends CameraParameterRequest {
  const FlashRequest({required this.enabled});
  final bool enabled;

  @override
  String get parameterName => 'flash';

  @override
  String toString() => 'FlashRequest(enabled=$enabled)';
}
