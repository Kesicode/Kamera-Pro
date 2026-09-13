/// Gallery capture metadata and repository.
library;

import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── CaptureMetadata ───

class CaptureMetadata extends Equatable {
  const CaptureMetadata({
    required this.id,
    required this.filePath,
    required this.timestamp,
    this.intentSummary,
    this.rawCommand,
    this.iso,
    this.shutterNs,
    this.whiteBalanceK,
    this.zoom,
    this.afMode,
    this.preset,
    this.educationalExplanation,
    this.aiGenerated = false,
  });

  final String id;
  final String filePath;
  final DateTime timestamp;
  final String? intentSummary;
  final String? rawCommand;
  final int? iso;
  final int? shutterNs;
  final int? whiteBalanceK;
  final double? zoom;
  final String? afMode;
  final String? preset;
  final String? educationalExplanation;
  final bool aiGenerated;

  String? get shutterLabel {
    if (shutterNs == null) return null;
    final s = shutterNs! / 1e9;
    return s >= 1.0 ? '${s.toStringAsFixed(1)}s' : '1/${(1.0 / s).round()}';
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'filePath': filePath,
    'timestamp': timestamp.toIso8601String(),
    'intentSummary': intentSummary, 'rawCommand': rawCommand,
    'iso': iso, 'shutterNs': shutterNs, 'whiteBalanceK': whiteBalanceK,
    'zoom': zoom, 'afMode': afMode, 'preset': preset,
    'educationalExplanation': educationalExplanation,
    'aiGenerated': aiGenerated,
  };

  factory CaptureMetadata.fromJson(Map<String, dynamic> j) => CaptureMetadata(
    id: j['id'] as String,
    filePath: j['filePath'] as String,
    timestamp: DateTime.parse(j['timestamp'] as String),
    intentSummary: j['intentSummary'] as String?,
    rawCommand: j['rawCommand'] as String?,
    iso: j['iso'] as int?,
    shutterNs: j['shutterNs'] as int?,
    whiteBalanceK: j['whiteBalanceK'] as int?,
    zoom: (j['zoom'] as num?)?.toDouble(),
    afMode: j['afMode'] as String?,
    preset: j['preset'] as String?,
    educationalExplanation: j['educationalExplanation'] as String?,
    aiGenerated: j['aiGenerated'] as bool? ?? false,
  );

  @override
  List<Object?> get props => [id, filePath, timestamp];
}

// ─── GalleryRepository ───

class GalleryRepository {
  GalleryRepository(this._box);

  static const String _boxName = 'kamera_pro_gallery';
  final Box<String> _box;

  static Future<GalleryRepository> open() async {
    final box = await Hive.openBox<String>(_boxName);
    return GalleryRepository(box);
  }

  Future<void> save(CaptureMetadata meta) =>
      _box.put(meta.id, jsonEncode(meta.toJson()));

  List<CaptureMetadata> getAll() => _box.values
      .map((j) => CaptureMetadata.fromJson(
            jsonDecode(j) as Map<String, dynamic>))
      .toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  CaptureMetadata? getById(String id) {
    final j = _box.get(id);
    return j == null
        ? null
        : CaptureMetadata.fromJson(jsonDecode(j) as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _box.delete(id);
  int get count => _box.length;
}

final galleryRepositoryProvider = FutureProvider<GalleryRepository>(
  (_) => GalleryRepository.open(),
);
