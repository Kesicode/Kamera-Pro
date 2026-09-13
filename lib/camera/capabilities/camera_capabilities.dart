/// Strongly typed camera capability model for Kamera Pro.
/// Populated at startup via capability detection — never hardcoded.
library;

import 'package:equatable/equatable.dart';

// ─────────────────────────── Enums ───────────────────────────

/// The physical position and type of a camera lens.
enum LensType {
  /// Primary rear wide-angle camera.
  wide,
  /// Ultra-wide rear camera.
  ultraWide,
  /// Telephoto / zoom camera.
  telephoto,
  /// Front-facing (selfie) camera.
  front,
  /// Unknown or unclassified lens.
  unknown,
}

/// Auto-focus modes supported by a camera.
enum AfMode {
  /// Fixed focus — no AF.
  fixed,
  /// Single-shot AF triggered on demand.
  single,
  /// Continuous focus for video/preview.
  continuous,
  /// Manual focus distance control.
  manual,
  /// Extended scene depth focus.
  extendedDepth,
}

/// Auto-exposure modes.
enum AeMode {
  /// Full auto exposure by camera.
  auto,
  /// Manual ISO and shutter control.
  manual,
  /// AE with flash control.
  flash,
  /// Anti-banding 50Hz.
  antiBanding50Hz,
  /// Anti-banding 60Hz.
  antiBanding60Hz,
}

/// Auto white-balance modes.
enum AwbMode {
  auto,
  incandescent,
  fluorescent,
  warmFluorescent,
  daylight,
  cloudyDaylight,
  twilight,
  shade,
  manual,
}

/// A simple inclusive range for numeric capabilities.
class Range<T extends num> extends Equatable {
  const Range({required this.min, required this.max});

  final T min;
  final T max;

  /// Returns true if [value] is within this range (inclusive).
  bool contains(T value) => value >= min && value <= max;

  /// Clamps [value] to this range.
  T clamp(T value) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  @override
  List<Object?> get props => [min, max];

  @override
  String toString() => '[$min, $max]';
}

// ─────────────────────────── CameraCapabilities ───────────────────────────

/// Full capability profile for a single camera sensor.
///
/// Populated at startup via Camera2 characteristics inspection.
/// This object is the source of truth for what the camera can and cannot do.
/// The parameter engine MUST consult this before generating any plan.
class CameraCapabilities extends Equatable {
  const CameraCapabilities({
    required this.cameraId,
    required this.lensType,
    required this.supportedAfModes,
    required this.supportedAeModes,
    required this.supportedAwbModes,
    required this.supportedResolutions,
    this.isoRange,
    this.shutterRangeNs,
    this.exposureCompensationRange,
    this.zoomRange,
    this.focalLengths = const [],
    this.minimumFocusDistanceDiopters,
    this.physicalApertures = const [],
    this.whiteBalanceRange,
    this.supportsManualIso = false,
    this.supportsManualShutter = false,
    this.supportsManualFocus = false,
    this.supportsManualWhiteBalance = false,
    this.supportsZoom = false,
    this.supportsFlash = false,
    this.supportsTorch = false,
    this.supportsRaw = false,
    this.supportsHdr = false,
    this.supportsStabilization = false,
    this.supportsDepth = false,
    this.maxFrameRate = 30,
    this.supportsBurst = false,
    this.isLogicalMultiCamera = false,
    this.physicalCameraIds = const [],
  });

  // ── Identity ──
  final String cameraId;
  final LensType lensType;

  // ── Exposure ──
  final Range<int>? isoRange; // ISO value range
  final Range<int>? shutterRangeNs; // Shutter in nanoseconds
  final Range<double>? exposureCompensationRange; // EV steps
  final bool supportsManualIso;
  final bool supportsManualShutter;

  // ── Focus ──
  final bool supportsManualFocus;
  final double? minimumFocusDistanceDiopters;
  final List<AfMode> supportedAfModes;

  // ── White Balance ──
  final bool supportsManualWhiteBalance;
  final Range<int>? whiteBalanceRange; // Kelvin
  final List<AwbMode> supportedAwbModes;

  // ── Zoom / Optics ──
  final bool supportsZoom;
  final Range<double>? zoomRange;
  final List<double> focalLengths; // mm
  final List<double> physicalApertures; // f-stops

  // ── Flash / Torch ──
  final bool supportsFlash;
  final bool supportsTorch;

  // ── Output formats ──
  final bool supportsRaw;
  final bool supportsHdr;
  final List<({int width, int height})> supportedResolutions;

  // ── Performance ──
  final int maxFrameRate;
  final bool supportsStabilization;
  final bool supportsBurst;

  // ── Multi-camera ──
  final bool isLogicalMultiCamera;
  final List<String> physicalCameraIds;

  // ── AE / AF / AWB modes ──
  final List<AeMode> supportedAeModes;

  // ── Depth ──
  final bool supportsDepth;

  // ── Computed helpers ──

  bool get isFrontFacing => lensType == LensType.front;
  bool get isRearFacing => !isFrontFacing;
  bool get hasFullManualControl =>
      supportsManualIso && supportsManualShutter && supportsManualFocus;
  bool supportsAfMode(AfMode mode) => supportedAfModes.contains(mode);
  bool supportsAeMode(AeMode mode) => supportedAeModes.contains(mode);
  bool supportsAwbMode(AwbMode mode) => supportedAwbModes.contains(mode);

  /// Returns the maximum zoom ratio supported, or 1.0 if zoom is unsupported.
  double get maxZoom => supportsZoom ? (zoomRange?.max ?? 1.0) : 1.0;

  @override
  List<Object?> get props => [
    cameraId, lensType, supportsManualIso, supportsManualShutter,
    supportsManualFocus, supportsManualWhiteBalance, supportsZoom,
    supportsFlash, supportsRaw,
  ];

  Map<String, dynamic> toDebugMap() => {
    'cameraId': cameraId,
    'lensType': lensType.name,
    'supportsManualIso': supportsManualIso,
    'isoRange': isoRange?.toString(),
    'supportsManualShutter': supportsManualShutter,
    'shutterRangeNs': shutterRangeNs?.toString(),
    'supportsManualFocus': supportsManualFocus,
    'supportsManualWhiteBalance': supportsManualWhiteBalance,
    'whiteBalanceRange': whiteBalanceRange?.toString(),
    'supportsZoom': supportsZoom,
    'zoomRange': zoomRange?.toString(),
    'supportsFlash': supportsFlash,
    'supportsRaw': supportsRaw,
    'supportsHdr': supportsHdr,
    'supportsStabilization': supportsStabilization,
    'maxFrameRate': maxFrameRate,
    'supportedAfModes': supportedAfModes.map((m) => m.name).toList(),
    'supportedAeModes': supportedAeModes.map((m) => m.name).toList(),
    'supportedAwbModes': supportedAwbModes.map((m) => m.name).toList(),
    'focalLengths': focalLengths,
    'physicalApertures': physicalApertures,
  };

  @override
  String toString() => 'CameraCapabilities(id=$cameraId, lens=${lensType.name})';
}
