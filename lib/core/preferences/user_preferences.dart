/// User preferences persisted across sessions using Hive.
library;

import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keys for the preferences Hive box.
class _Keys {
  static const String educationalMode = 'educational_mode';
  static const String defaultPreset = 'default_preset';
  static const String aiEnabled = 'ai_enabled';
  static const String cloudAiEnabled = 'cloud_ai_enabled';
  static const String preferredCamera = 'preferred_camera';
  static const String debugMode = 'debug_mode';
  static const String onboardingCompleted = 'onboarding_completed';
}

/// Persisted user preferences for Kamera Pro.
class UserPreferences {
  UserPreferences(this._box);

  final Box<dynamic> _box;
  static const String _boxName = 'kamera_pro_prefs';

  /// Opens the Hive box. Must be called before first use.
  static Future<UserPreferences> open() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<dynamic>(_boxName);
    return UserPreferences(box);
  }

  // ─────────────────────────── Educational Mode ───────────────────────────

  bool get educationalMode =>
      _box.get(_Keys.educationalMode, defaultValue: true) as bool;
  set educationalMode(bool value) => _box.put(_Keys.educationalMode, value);
  Future<void> setEducationalMode(bool v) => _box.put(_Keys.educationalMode, v);

  // ─────────────────────────── AI Settings ───────────────────────────

  bool get aiEnabled =>
      _box.get(_Keys.aiEnabled, defaultValue: true) as bool;
  set aiEnabled(bool value) => _box.put(_Keys.aiEnabled, value);
  Future<void> setAiEnabled(bool v) => _box.put(_Keys.aiEnabled, v);

  bool get cloudAiEnabled =>
      _box.get(_Keys.cloudAiEnabled, defaultValue: true) as bool;
  set cloudAiEnabled(bool value) => _box.put(_Keys.cloudAiEnabled, value);
  Future<void> setCloudAiEnabled(bool v) => _box.put(_Keys.cloudAiEnabled, v);

  // ─────────────────────────── Camera Settings ───────────────────────────

  String? get preferredCameraId =>
      _box.get(_Keys.preferredCamera) as String?;
  Future<void> setPreferredCameraId(String id) =>
      _box.put(_Keys.preferredCamera, id);

  // ─────────────────────────── Presets ───────────────────────────

  String get defaultPreset =>
      _box.get(_Keys.defaultPreset, defaultValue: 'Natural') as String;
  Future<void> setDefaultPreset(String name) =>
      _box.put(_Keys.defaultPreset, name);

  // ─────────────────────────── Debug ───────────────────────────

  bool get debugMode =>
      _box.get(_Keys.debugMode, defaultValue: false) as bool;
  set debugMode(bool value) => _box.put(_Keys.debugMode, value);
  Future<void> setDebugMode(bool v) => _box.put(_Keys.debugMode, v);

  // ─────────────────────────── Onboarding ───────────────────────────

  bool get onboardingCompleted =>
      _box.get(_Keys.onboardingCompleted, defaultValue: false) as bool;
  Future<void> completeOnboarding() =>
      _box.put(_Keys.onboardingCompleted, true);
}

/// Riverpod async provider for [UserPreferences].
final userPreferencesProvider = FutureProvider<UserPreferences>(
  (_) => UserPreferences.open(),
);
