/// Camera Hardware Abstraction Layer interfaces.
/// All camera implementations must satisfy these contracts.
/// The UI layer only sees these interfaces — never the concrete driver.
library;

import 'package:equatable/equatable.dart';
import '../capabilities/camera_capabilities.dart';
import '../controls/camera_parameter_request.dart';
import '../../core/common/result.dart';

// ─────────────────────────── Error Types ───────────────────────────

enum CameraErrorType {
  initializationError,
  permissionDenied,
  deviceNotFound,
  sessionLost,
  unsupportedFeature,
  invalidParameter,
  captureFailed,
  hardwareError,
  unknown,
}

class CameraError extends Equatable {
  const CameraError({
    required this.type,
    required this.message,
    this.unsupportedParameterName,
    this.cause,
  });

  final CameraErrorType type;
  final String message;
  final String? unsupportedParameterName;
  final Object? cause;

  bool get isRecoverable => type != CameraErrorType.permissionDenied &&
      type != CameraErrorType.deviceNotFound;

  @override
  List<Object?> get props => [type, message, unsupportedParameterName];

  @override
  String toString() => 'CameraError(${type.name}: $message)';
}

// ─────────────────────────── Session State ───────────────────────────

enum CameraSessionStatus {
  uninitialized,
  starting,
  ready,
  capturing,
  closing,
  error,
}

class CameraSessionState extends Equatable {
  const CameraSessionState({
    required this.status,
    this.activeCameraId,
    this.error,
  });

  final CameraSessionStatus status;
  final String? activeCameraId;
  final CameraError? error;

  bool get isReady => status == CameraSessionStatus.ready;
  bool get hasError => error != null;

  @override
  List<Object?> get props => [status, activeCameraId, error];
}

// ─────────────────────────── Capture Result ───────────────────────────

class CaptureResult extends Equatable {
  const CaptureResult({
    required this.filePath,
    required this.timestamp,
    this.widthPx,
    this.heightPx,
    this.fileSizeBytes,
  });

  final String filePath;
  final DateTime timestamp;
  final int? widthPx;
  final int? heightPx;
  final int? fileSizeBytes;

  @override
  List<Object?> get props => [filePath, timestamp];
}

// ─────────────────────────── Interfaces ───────────────────────────

/// Discovers available cameras on the device.
abstract interface class CameraDiscovery {
  Future<List<String>> discoverCameraIds();
  Future<Result<CameraCapabilities, CameraError>> getCapabilities(String cameraId);
  Future<Map<String, CameraCapabilities>> getAllCapabilities();
}

/// Manages the camera session lifecycle.
abstract interface class CameraSession {
  CameraSessionState get state;
  Stream<CameraSessionState> get stateStream;
  Future<Result<void, CameraError>> start(String cameraId);
  Future<Result<void, CameraError>> switchCamera(String cameraId);
  Future<void> stop();
}

/// Applies validated parameters to the camera.
abstract interface class CameraParameterController {
  Future<Result<void, CameraError>> setZoom(double ratio);
  Future<Result<void, CameraError>> setFlash({required bool enabled});
  Future<Result<void, CameraError>> setTorch({required bool enabled});
  Future<Result<void, CameraError>> setIso(int iso);
  Future<Result<void, CameraError>> setShutterNs(int shutterNs);
  Future<Result<void, CameraError>> setWhiteBalanceK(int kelvin);
  Future<Result<void, CameraError>> setExposureCompensation(double ev);
  Future<Result<void, CameraError>> setAfMode(AfMode mode);
  Future<Result<void, CameraError>> triggerAutoFocus();
  Future<Map<String, CameraError>> applyParameters(List<CameraParameterRequest> requests);
}

/// Captures photos and video.
abstract interface class CameraCaptureController {
  Future<Result<CaptureResult, CameraError>> capturePhoto();
  Future<Result<void, CameraError>> startVideoRecording();
  Future<Result<CaptureResult, CameraError>> stopVideoRecording();
  bool get isRecording;
}
