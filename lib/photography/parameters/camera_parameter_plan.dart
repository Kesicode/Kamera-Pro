/// A complete validated plan of camera parameters to apply.
/// This is the output of the CameraParameterEngine and input to the HAL.
library;

import 'package:equatable/equatable.dart';
import '../../camera/capabilities/camera_capabilities.dart';
import 'camera_parameter.dart';

/// A complete set of camera parameters to apply to the hardware.
/// Each field may be null if no change is requested for that parameter.
class CameraParameterPlan extends Equatable {
  const CameraParameterPlan({
    this.iso,
    this.shutterNs,
    this.whiteBalanceK,
    this.exposureCompensation,
    this.zoom,
    this.afMode,
    this.flash,
    this.torch,
    this.useAutoExposure = true,
    this.useAutoWhiteBalance = true,
    this.educationalExplanation,
    this.rejectedParameters = const [],
    this.warnings = const [],
  });

  final ParameterValue<int>? iso;
  final ParameterValue<int>? shutterNs;
  final ParameterValue<int>? whiteBalanceK;
  final ParameterValue<double>? exposureCompensation;
  final ParameterValue<double>? zoom;
  final ParameterValue<AfMode>? afMode;
  final ParameterValue<bool>? flash;
  final ParameterValue<bool>? torch;
  final bool useAutoExposure;
  final bool useAutoWhiteBalance;
  final String? educationalExplanation;
  final List<RejectedParameter> rejectedParameters;
  final List<String> warnings;

  bool get hasRejections => rejectedParameters.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;

  /// Returns a human-readable summary of this plan for the UI overlay.
  String get parameterSummary {
    final parts = <String>[];
    if (iso != null) parts.add('ISO ${iso!.value}');
    if (shutterNs != null) {
      final secs = shutterNs!.value / 1e9;
      final label = secs >= 1.0
          ? '${secs.toStringAsFixed(1)}s'
          : '1/${(1.0 / secs).round()}';
      parts.add(label);
    }
    if (whiteBalanceK != null) parts.add('${whiteBalanceK!.value}K');
    if (zoom != null) parts.add('${zoom!.value.toStringAsFixed(1)}x');
    if (afMode != null) parts.add(_afLabel(afMode!.value));
    if (flash != null) parts.add(flash!.value ? 'Flash ON' : 'Flash OFF');
    return parts.join(' • ');
  }

  static String _afLabel(AfMode mode) => switch (mode) {
    AfMode.fixed => 'Focus: Fixed',
    AfMode.single => 'AF Single',
    AfMode.continuous => 'AF Continuous',
    AfMode.manual => 'Focus: Manual',
    AfMode.extendedDepth => 'AF Extended',
  };

  @override
  List<Object?> get props => [
    iso, shutterNs, whiteBalanceK, exposureCompensation,
    zoom, afMode, flash, torch, useAutoExposure, useAutoWhiteBalance,
  ];

  CameraParameterPlan copyWith({
    ParameterValue<int>? iso,
    ParameterValue<int>? shutterNs,
    ParameterValue<int>? whiteBalanceK,
    ParameterValue<double>? exposureCompensation,
    ParameterValue<double>? zoom,
    ParameterValue<AfMode>? afMode,
    ParameterValue<bool>? flash,
    ParameterValue<bool>? torch,
    bool? useAutoExposure,
    bool? useAutoWhiteBalance,
    String? educationalExplanation,
    List<RejectedParameter>? rejectedParameters,
    List<String>? warnings,
  }) => CameraParameterPlan(
    iso: iso ?? this.iso,
    shutterNs: shutterNs ?? this.shutterNs,
    whiteBalanceK: whiteBalanceK ?? this.whiteBalanceK,
    exposureCompensation: exposureCompensation ?? this.exposureCompensation,
    zoom: zoom ?? this.zoom,
    afMode: afMode ?? this.afMode,
    flash: flash ?? this.flash,
    torch: torch ?? this.torch,
    useAutoExposure: useAutoExposure ?? this.useAutoExposure,
    useAutoWhiteBalance: useAutoWhiteBalance ?? this.useAutoWhiteBalance,
    educationalExplanation: educationalExplanation ?? this.educationalExplanation,
    rejectedParameters: rejectedParameters ?? this.rejectedParameters,
    warnings: warnings ?? this.warnings,
  );
}

/// Describes a parameter that was requested but could not be applied.
class RejectedParameter extends Equatable {
  const RejectedParameter({
    required this.parameterName,
    required this.requestedValue,
    required this.reason,
    this.closestSupported,
    this.userMessage,
  });

  final String parameterName;
  final dynamic requestedValue;
  final String reason;
  final dynamic closestSupported;
  final String? userMessage;

  @override
  List<Object?> get props => [parameterName, requestedValue, reason];

  @override
  String toString() =>
      'RejectedParameter(name=$parameterName, requested=$requestedValue, reason=$reason)';
}
