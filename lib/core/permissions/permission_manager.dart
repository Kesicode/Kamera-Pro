/// Runtime permission management for camera and microphone.
library;

import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logging/app_logger.dart';
import '../common/result.dart';

/// Describes the current permission state of required app permissions.
class PermissionState {
  const PermissionState({
    required this.cameraGranted,
    required this.microphoneGranted,
    required this.storageGranted,
  });

  final bool cameraGranted;
  final bool microphoneGranted;
  final bool storageGranted;

  bool get allRequired => cameraGranted && microphoneGranted;
  bool get allGranted => cameraGranted && microphoneGranted && storageGranted;

  PermissionState copyWith({
    bool? cameraGranted,
    bool? microphoneGranted,
    bool? storageGranted,
  }) => PermissionState(
    cameraGranted: cameraGranted ?? this.cameraGranted,
    microphoneGranted: microphoneGranted ?? this.microphoneGranted,
    storageGranted: storageGranted ?? this.storageGranted,
  );

  @override
  String toString() =>
      'PermissionState(camera=$cameraGranted, mic=$microphoneGranted, storage=$storageGranted)';
}

/// Manages requesting and querying runtime permissions.
class PermissionManager {
  const PermissionManager();

  /// Queries current permission status without requesting.
  Future<PermissionState> query() async {
    final camera = await Permission.camera.status;
    final microphone = await Permission.microphone.status;
    final storage = await Permission.storage.status;
    return PermissionState(
      cameraGranted: camera.isGranted,
      microphoneGranted: microphone.isGranted,
      storageGranted: storage.isGranted,
    );
  }

  /// Requests camera and microphone permissions.
  Future<Result<PermissionState, String>> requestRequired() async {
    log.app('Requesting required permissions: camera + microphone');
    final statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    final camera = statuses[Permission.camera]!;
    final microphone = statuses[Permission.microphone]!;
    final storage = await Permission.storage.status;

    final state = PermissionState(
      cameraGranted: camera.isGranted,
      microphoneGranted: microphone.isGranted,
      storageGranted: storage.isGranted,
    );

    if (!state.cameraGranted) {
      log.warning('Camera permission denied — app cannot function');
      return Result.err('Camera permission is required to use Kamera Pro.');
    }

    if (!state.microphoneGranted) {
      log.warning('Microphone permission denied — voice commands unavailable');
    }

    log.app('Permissions: $state');
    return Result.ok(state);
  }

  /// Requests storage permission for saving photos.
  Future<bool> requestStorage() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Opens app settings so the user can manually grant permissions.
  Future<void> openSettings() => openAppSettings();
}

/// Riverpod provider for [PermissionManager].
final permissionManagerProvider = Provider<PermissionManager>(
  (_) => const PermissionManager(),
);

/// Riverpod provider for the current [PermissionState].
final permissionStateProvider =
    FutureProvider<PermissionState>((ref) async {
  final manager = ref.watch(permissionManagerProvider);
  return manager.query();
});
