/// PhotographyAI interface and context types.
library;

import '../../photography/intent/photography_intent.dart';

/// Context about the current scene passed alongside a voice command.
class PhotographyContext {
  const PhotographyContext({
    this.currentScene,
    this.hasFaceDetected = false,
    this.estimatedLux,
    this.currentCameraId,
    this.currentPreset,
    this.isOutdoor,
  });

  final SceneType? currentScene;
  final bool hasFaceDetected;
  final double? estimatedLux;
  final String? currentCameraId;
  final String? currentPreset;
  final bool? isOutdoor;

  Map<String, dynamic> toMap() => {
    if (currentScene != null) 'currentScene': currentScene!.name,
    'hasFaceDetected': hasFaceDetected,
    if (estimatedLux != null) 'estimatedLux': estimatedLux,
    if (currentCameraId != null) 'currentCameraId': currentCameraId,
    if (currentPreset != null) 'currentPreset': currentPreset,
    if (isOutdoor != null) 'isOutdoor': isOutdoor,
  };
}

/// The photography AI interface.
abstract interface class PhotographyAI {
  Future<PhotographyIntent> interpretCommand(
    String commandText,
    PhotographyContext context,
  );
}
