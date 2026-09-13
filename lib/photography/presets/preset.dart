/// Photography presets library.
library;

import 'package:equatable/equatable.dart';
import '../intent/photography_intent.dart';

abstract class Preset extends Equatable {
  const Preset();
  String get name;
  String get description;
  String get icon;
  PhotographyIntent get intent;

  @override
  List<Object?> get props => [name];
}

class PortraitPreset extends Preset {
  const PortraitPreset();
  @override String get name => 'Portrait';
  @override String get description => 'Subject-focused, soft background';
  @override String get icon => '🧑';
  @override PhotographyIntent get intent => const PhotographyIntent(
    captureType: CaptureType.photo, scene: SceneType.portrait,
    focusPreference: FocusPreference.face, flashIntent: FlashIntent.off,
    exposurePreference: ExposurePreference.faceExposed,
    rawCommand: 'Portrait preset', confidence: 1.0,
  );
}

class CinematicPreset extends Preset {
  const CinematicPreset();
  @override String get name => 'Cinematic';
  @override String get description => 'Dramatic cinematic look';
  @override String get icon => '🎬';
  @override PhotographyIntent get intent => const PhotographyIntent(
    captureType: CaptureType.photo, scene: SceneType.portrait,
    style: StyleType.cinematic, lightingIntent: LightingIntent.dramatic,
    flashIntent: FlashIntent.off, rawCommand: 'Cinematic preset', confidence: 1.0,
  );
}

class VintagePreset extends Preset {
  const VintagePreset();
  @override String get name => 'Vintage';
  @override String get description => 'Classic film photography look';
  @override String get icon => '📷';
  @override PhotographyIntent get intent => const PhotographyIntent(
    captureType: CaptureType.photo, style: StyleType.vintage,
    lightingIntent: LightingIntent.warm, flashIntent: FlashIntent.off,
    rawCommand: 'Vintage preset', confidence: 1.0,
  );
}

class NightPreset extends Preset {
  const NightPreset();
  @override String get name => 'Night';
  @override String get description => 'Optimized for low-light scenes';
  @override String get icon => '🌙';
  @override PhotographyIntent get intent => const PhotographyIntent(
    captureType: CaptureType.photo, scene: SceneType.night,
    lightingIntent: LightingIntent.dark, flashIntent: FlashIntent.off,
    rawCommand: 'Night preset', confidence: 1.0,
  );
}

class LandscapePreset extends Preset {
  const LandscapePreset();
  @override String get name => 'Landscape';
  @override String get description => 'Wide scene with deep focus';
  @override String get icon => '🏞️';
  @override PhotographyIntent get intent => const PhotographyIntent(
    captureType: CaptureType.photo, scene: SceneType.landscape,
    exposurePreference: ExposurePreference.balanced, flashIntent: FlashIntent.off,
    rawCommand: 'Landscape preset', confidence: 1.0,
  );
}

class SportsPreset extends Preset {
  const SportsPreset();
  @override String get name => 'Sports';
  @override String get description => 'Freeze fast motion';
  @override String get icon => '⚽';
  @override PhotographyIntent get intent => const PhotographyIntent(
    captureType: CaptureType.photo, scene: SceneType.sports,
    subjectMotion: SubjectMotion.running, flashIntent: FlashIntent.off,
    rawCommand: 'Sports preset', confidence: 1.0,
  );
}

class NaturalPreset extends Preset {
  const NaturalPreset();
  @override String get name => 'Natural';
  @override String get description => 'Clean, auto-optimized';
  @override String get icon => '🌿';
  @override PhotographyIntent get intent => const PhotographyIntent(
    captureType: CaptureType.photo, style: StyleType.natural,
    rawCommand: 'Natural preset', confidence: 1.0,
  );
}

class PresetLibrary {
  const PresetLibrary();

  static const List<Preset> all = [
    PortraitPreset(),
    CinematicPreset(),
    VintagePreset(),
    NightPreset(),
    LandscapePreset(),
    SportsPreset(),
    NaturalPreset(),
  ];

  Preset? findByName(String name) {
    for (final p in all) {
      if (p.name.toLowerCase() == name.toLowerCase()) return p;
    }
    return null;
  }
}
