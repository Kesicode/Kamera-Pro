/// Main camera screen — the primary UI of Kamera Pro.
///
/// Layout (top to bottom):
///   [Settings icon]
///   [Live camera preview — fills screen]
///   [AI status indicator]
///   [Parameter strip: ISO • Shutter • WB]
///   [Zoom selector: 1x 2x 3x 5x]
///   [Controls row: Gallery | CAPTURE | Mic/AI]
///   [Presets bar]
library;


import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../camera/capabilities/camera_capabilities.dart';
import '../../photography/intent/photography_intent.dart';
import '../../photography/parameters/camera_parameter_plan.dart';
import '../../photography/reasoning/photography_reasoning_engine.dart';
import '../../photography/presets/preset.dart';
import '../../photography/parameters/parameter_validator.dart';
import '../../voice/speech/speech_recognizer.dart';
import '../../voice/speech/android_speech_recognizer.dart';
import '../../ai/api/photography_ai.dart';
import '../../ai/providers/rule_based_photography_ai.dart';
import '../../ai/providers/gemini_photography_ai.dart';
import '../../core/logging/app_logger.dart';
import '../controls/manual_controls_panel.dart';
import '../assistant/voice_overlay.dart';
import '../assistant/ai_panel.dart';
import '../presets/presets_bar.dart';

// ─────────────────────────────── State ───────────────────────────────

enum AiUiState { idle, listening, understanding, planning, applying, ready, error }

class CameraScreenState {
  const CameraScreenState({
    this.aiState = AiUiState.idle,
    this.currentPlan,
    this.currentIntent,
    this.lastCommand,
    this.statusMessage,
    this.capabilities,
    this.isManualControlsOpen = false,
    this.isAiPanelOpen = false,
    this.selectedPreset,
    this.userOverrides = const {},
    this.rejectionMessages = const [],
    this.currentZoom = 1.0,
  });

  final AiUiState aiState;
  final CameraParameterPlan? currentPlan;
  final PhotographyIntent? currentIntent;
  final String? lastCommand;
  final String? statusMessage;
  final CameraCapabilities? capabilities;
  final bool isManualControlsOpen;
  final bool isAiPanelOpen;
  final Preset? selectedPreset;
  final Map<String, dynamic> userOverrides;
  final List<String> rejectionMessages;
  final double currentZoom;

  CameraScreenState copyWith({
    AiUiState? aiState,
    CameraParameterPlan? currentPlan,
    PhotographyIntent? currentIntent,
    String? lastCommand,
    String? statusMessage,
    CameraCapabilities? capabilities,
    bool? isManualControlsOpen,
    bool? isAiPanelOpen,
    Preset? selectedPreset,
    Map<String, dynamic>? userOverrides,
    List<String>? rejectionMessages,
    double? currentZoom,
  }) => CameraScreenState(
    aiState: aiState ?? this.aiState,
    currentPlan: currentPlan ?? this.currentPlan,
    currentIntent: currentIntent ?? this.currentIntent,
    lastCommand: lastCommand ?? this.lastCommand,
    statusMessage: statusMessage ?? this.statusMessage,
    capabilities: capabilities ?? this.capabilities,
    isManualControlsOpen: isManualControlsOpen ?? this.isManualControlsOpen,
    isAiPanelOpen: isAiPanelOpen ?? this.isAiPanelOpen,
    selectedPreset: selectedPreset ?? this.selectedPreset,
    userOverrides: userOverrides ?? this.userOverrides,
    rejectionMessages: rejectionMessages ?? this.rejectionMessages,
    currentZoom: currentZoom ?? this.currentZoom,
  );
}

// ─────────────────────────────── Screen ───────────────────────────────

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  CameraScreenState _state = const CameraScreenState();
  SpeechRecognizer? _speech;
  PhotographyAI? _ruleAi;
  PhotographyAI? _geminiAi;
  final _reasoningEngine = const PhotographyReasoningEngine();
  final _validator = const ParameterValidator();
  final _uuid = const Uuid();

  // camerawesome
  SensorConfig? _sensorConfig;
  CameraState? _cameraState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSpeech();
    _initAi();
  }

  Future<void> _initSpeech() async {
    _speech = AndroidSpeechRecognizer();
    await _speech!.initialize();
    log.voice('Speech recognizer ready: ${_speech!.isAvailable}');
  }

  void _initAi() {
    _ruleAi = const RuleBasedPhotographyAI();
    _geminiAi = ref.read(geminiAiProvider);
    log.ai('AI providers ready. Gemini: ${_geminiAi != null}');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _speech?.dispose();
    super.dispose();
  }

  // ─────────────────── Voice Command Flow ───────────────────

  Future<void> _startVoiceCommand() async {
    if (_speech == null || !_speech!.isAvailable) {
      _setStatus(AiUiState.error, 'Microphone not available');
      return;
    }
    setState(() {
      _state = _state.copyWith(
        aiState: AiUiState.listening,
        statusMessage: 'Listening...',
      );
    });

    final result = await _speech!.listenOnce();

    switch (result) {
      case SpeechSuccess(:final text):
        await _processCommand(text);
      case SpeechEmpty():
        _setStatus(AiUiState.idle, null);
      case SpeechError(:final isPermissionDenied):
        _setStatus(
          AiUiState.error,
          isPermissionDenied
              ? 'Microphone permission denied. Enable in Settings.'
              : 'Could not understand. Please try again.',
        );
    }
  }

  Future<void> _processCommand(String text) async {
    log.voice('Processing: "$text"');
    setState(() {
      _state = _state.copyWith(
        aiState: AiUiState.understanding,
        lastCommand: text,
        statusMessage: 'Understanding...',
      );
    });

    try {
      final context = PhotographyContext(hasFaceDetected: false);
      final ruleResult = await _ruleAi!.interpretCommand(text, context);
      PhotographyIntent intent = ruleResult;

      if (ruleResult.confidence < 0.85 && _geminiAi != null) {
        setState(() {
          _state = _state.copyWith(statusMessage: 'Analyzing...');
        });
        try {
          intent = await _geminiAi!.interpretCommand(text, context);
        } catch (e) {
          log.ai('Gemini failed, using rule-based: $e');
        }
      }

      setState(() {
        _state = _state.copyWith(
          aiState: AiUiState.planning,
          currentIntent: intent,
          statusMessage: 'Planning...',
        );
      });

      final caps = _state.capabilities ?? _defaultCapabilities();
      final rawPlan = _reasoningEngine.reason(intent, ReasoningContext(capabilities: caps));
      final validation = _validator.validate(rawPlan, caps);

      setState(() {
        _state = _state.copyWith(aiState: AiUiState.applying, statusMessage: 'Applying...');
      });

      await _applyPlan(validation.validatedPlan);

      setState(() {
        _state = _state.copyWith(
          aiState: AiUiState.ready,
          currentPlan: validation.validatedPlan,
          isAiPanelOpen: true,
          statusMessage: null,
          rejectionMessages: validation.rejected.map((r) => r.userMessage ?? r.reason).toList(),
        );
      });

      if (intent.hasConflicts) _showSnack(intent.conflictWarnings.first);
      if (validation.hasRejections) {
        _showSnack(validation.rejected.first.userMessage ?? 'Some settings not supported.');
      }
    } catch (e, st) {
      log.ai('Command processing failed', error: e, stackTrace: st);
      _setStatus(AiUiState.error, 'Could not process command. Please try again.');
    }
  }

  /// Apply a validated plan to the camerawesome SensorConfig.
  /// camerawesome 2.5.0 SensorConfig exposes:
  ///   setZoom(0.0-1.0), setFlashMode(FlashMode), setBrightness(0.0-1.0)
  /// ISO/Shutter/WB are note directly settable — we map EV to brightness.
  Future<void> _applyPlan(CameraParameterPlan plan) async {
    if (_sensorConfig == null) return;
    try {
      // Zoom: normalize ratio → 0.0–1.0 scale
      if (plan.zoom != null) {
        final caps = _state.capabilities;
        final maxRatio = caps?.zoomRange?.max ?? 10.0;
        final minRatio = caps?.zoomRange?.min ?? 1.0;
        final ratio = plan.zoom!.value;
        final normalized = ((ratio - minRatio) / (maxRatio - minRatio)).clamp(0.0, 1.0);
        await _sensorConfig!.setZoom(normalized);
        setState(() {
          _state = _state.copyWith(currentZoom: ratio);
        });
      }

      // Flash
      if (plan.flash != null) {
        await _sensorConfig!.setFlashMode(
          plan.flash!.value ? FlashMode.on : FlashMode.none,
        );
      }

      // Exposure compensation → brightness (0.0-1.0 mapping from -2..+2 EV)
      if (plan.exposureCompensation != null) {
        final ev = plan.exposureCompensation!.value.clamp(-2.0, 2.0);
        final brightness = ((ev + 2.0) / 4.0).clamp(0.0, 1.0);
        _sensorConfig!.setBrightness(brightness);
      }

      log.params('Applied plan: ${plan.parameterSummary}');
    } catch (e) {
      log.camera('Error applying plan', error: e);
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraState == null) return;
    _cameraState!.when(
      onPhotoMode: (photoState) async {
        try {
          await photoState.takePhoto();
          _showSnack('📸 Photo saved!');
        } catch (e) {
          log.capture('Capture failed', error: e);
          _showSnack('Capture failed. Please try again.');
        }
      },
      onVideoMode: (_) {},
      onVideoRecordingMode: (_) {},
      onPreviewMode: (_) {},
    );
  }

  Future<void> _setZoom(double zoomRatio) async {
    if (_sensorConfig == null) return;
    final caps = _state.capabilities;
    final maxRatio = caps?.zoomRange?.max ?? 10.0;
    final minRatio = caps?.zoomRange?.min ?? 1.0;
    final normalized = ((zoomRatio - minRatio) / (maxRatio - minRatio)).clamp(0.0, 1.0);
    await _sensorConfig!.setZoom(normalized);
    setState(() {
      _state = _state.copyWith(currentZoom: zoomRatio);
    });
  }

  void _onPresetSelected(Preset preset) async {
    setState(() {
      _state = _state.copyWith(selectedPreset: preset);
    });
    await _processCommand('${preset.name} preset');
  }

  void _onManualParameterChanged(String param, dynamic value) async {
    if (_sensorConfig == null) return;
    switch (param) {
      case 'zoom':
        await _setZoom(value as double);
      case 'flash':
        await _sensorConfig!.setFlashMode(
          (value as bool) ? FlashMode.on : FlashMode.none,
        );
      case 'ev':
        final ev = (value as double).clamp(-2.0, 2.0);
        _sensorConfig!.setBrightness(((ev + 2.0) / 4.0).clamp(0.0, 1.0));
    }
  }

  void _setStatus(AiUiState state, String? message) {
    setState(() {
      _state = _state.copyWith(aiState: state, statusMessage: message);
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFF1A1A1A),
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    ));
  }

  CameraCapabilities _defaultCapabilities() => CameraCapabilities(
    cameraId: '0',
    lensType: LensType.wide,
    supportsManualIso: false,
    supportsManualShutter: false,
    supportsManualFocus: false,
    supportsManualWhiteBalance: false,
    supportsZoom: true,
    zoomRange: const Range(min: 1.0, max: 10.0),
    supportsFlash: true,
    supportsTorch: true,
    supportsRaw: false,
    supportsHdr: false,
    supportsStabilization: true,
    supportsBurst: false,
    maxFrameRate: 30,
    exposureCompensationRange: const Range(min: -2.0, max: 2.0),
    supportedAfModes: [AfMode.single, AfMode.continuous],
    supportedAeModes: [AeMode.auto],
    supportedAwbModes: [AwbMode.auto],
    focalLengths: [4.25],
    supportedResolutions: [(width: 1920, height: 1080)],
  );

  // ─────────────────── Build ───────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildCameraPreview(),
          _buildTopBar(),
          if (_state.aiState != AiUiState.idle && _state.aiState != AiUiState.ready)
            _buildAiStatusOverlay(),
          if (_state.aiState == AiUiState.listening)
            VoiceListeningOverlay(command: _state.lastCommand),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomControls(),
          ),
          if (_state.isAiPanelOpen && _state.currentPlan != null)
            Positioned(
              bottom: 200, left: 0, right: 0,
              child: AiPanel(
                intent: _state.currentIntent,
                plan: _state.currentPlan!,
                onClose: () => setState(() {
                  _state = _state.copyWith(isAiPanelOpen: false);
                }),
              ),
            ),
          if (_state.isManualControlsOpen && _state.capabilities != null)
            Positioned(
              bottom: 200, left: 0, right: 0,
              child: ManualControlsPanel(
                capabilities: _state.capabilities!,
                currentPlan: _state.currentPlan,
                onParameterChanged: _onManualParameterChanged,
                onClose: () => setState(() {
                  _state = _state.copyWith(isManualControlsOpen: false);
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return CameraAwesomeBuilder.custom(
      saveConfig: SaveConfig.photo(
        pathBuilder: (sensors) async {
          final dir = await getTemporaryDirectory();
          final id = _uuid.v4();
          return SingleCaptureRequest(
            '${dir.path}/kamera_$id.jpg',
            sensors.first,
          );
        },
      ),
      sensorConfig: SensorConfig.single(
        sensor: Sensor.position(SensorPosition.back),
        flashMode: FlashMode.none,
        aspectRatio: CameraAspectRatios.ratio_16_9,
        zoom: 0.0,
      ),
      onMediaCaptureEvent: (event) {
        switch (event.status) {
          case MediaCaptureStatus.capturing:
            log.capture('Capturing...');
          case MediaCaptureStatus.success:
            log.capture('Captured: ${event.captureRequest}');
          case MediaCaptureStatus.failure:
            log.capture('Failed', error: event.exception);
        }
      },
      builder: (cameraState, preview) {
        _cameraState = cameraState;
        cameraState.when(
          onPhotoMode: (photoState) {
            _sensorConfig = photoState.sensorConfig;
            if (_state.capabilities == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _state = _state.copyWith(
                        capabilities: _defaultCapabilities());
                  });
                }
              });
            }
          },
          onVideoMode: (v) { _sensorConfig = v.sensorConfig; },
          onVideoRecordingMode: (v) { _sensorConfig = v.sensorConfig; },
          onPreviewMode: (p) { _sensorConfig = p.sensorConfig; },
        );
        // Return a transparent overlay — the camera preview is rendered
        // automatically by CameraAwesomeBuilder behind this widget.
        return const SizedBox.expand();
      },
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 0, right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'KAMERA PRO',
              style: TextStyle(
                color: Color(0xFFE8C547),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            Row(
              children: [
                if (_state.currentPlan != null)
                  IconButton(
                    icon: const Icon(Icons.auto_awesome,
                        color: Color(0xFFE8C547), size: 20),
                    onPressed: () => setState(() {
                      _state = _state.copyWith(
                          isAiPanelOpen: !_state.isAiPanelOpen);
                    }),
                  ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiStatusOverlay() {
    final label = switch (_state.aiState) {
      AiUiState.listening => 'Listening...',
      AiUiState.understanding => 'Understanding...',
      AiUiState.planning => 'Planning...',
      AiUiState.applying => 'Applying...',
      AiUiState.error => _state.statusMessage ?? 'Error',
      _ => '',
    };
    final color = _state.aiState == AiUiState.error
        ? Colors.red.shade400
        : const Color(0xFFE8C547);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 0, right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_state.aiState != AiUiState.error)
                SizedBox(
                  width: 12, height: 12,
                  child: CircularProgressIndicator(
                      color: color, strokeWidth: 2),
                ),
              if (_state.aiState != AiUiState.error) const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(color: color, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black, Colors.transparent],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_state.currentPlan != null)
              _buildParameterStrip(_state.currentPlan!),
            if (_state.lastCommand != null && _state.aiState == AiUiState.ready)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  '"${_state.lastCommand}"',
                  style: const TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 4),
            _buildZoomSelector(),
            const SizedBox(height: 16),
            _buildCaptureRow(),
            const SizedBox(height: 12),
            PresetsBar(
              onPresetSelected: _onPresetSelected,
              selectedPreset: _state.selectedPreset,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterStrip(CameraParameterPlan plan) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _paramChip('ISO', plan.iso != null ? '${plan.iso!.value}' : 'AUTO',
              plan.iso?.userLocked ?? false),
          _paramChip('1/T',
              plan.shutterNs != null ? _nsLabel(plan.shutterNs!.value) : 'AUTO',
              plan.shutterNs?.userLocked ?? false),
          _paramChip('WB',
              plan.whiteBalanceK != null ? '${plan.whiteBalanceK!.value}K' : 'AUTO',
              plan.whiteBalanceK?.userLocked ?? false),
          _paramChip('EV',
              plan.exposureCompensation != null
                  ? '${plan.exposureCompensation!.value >= 0 ? '+' : ''}${plan.exposureCompensation!.value.toStringAsFixed(1)}'
                  : '0',
              plan.exposureCompensation?.userLocked ?? false),
        ],
      ),
    );
  }

  Widget _paramChip(String label, String value, bool locked) {
    return GestureDetector(
      onTap: () => setState(() {
        _state = _state.copyWith(isManualControlsOpen: true);
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: locked
                ? const Color(0xFFE8C547).withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF888888), fontSize: 9, letterSpacing: 1)),
            Text(value,
                style: TextStyle(
                  color: locked ? const Color(0xFFE8C547) : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomSelector() {
    final maxZoom = _state.capabilities?.maxZoom ?? 10.0;
    final zoomLevels = [1.0, 2.0, 3.0, 5.0].where((z) => z <= maxZoom).toList();
    if (zoomLevels.length < 2) return const SizedBox.shrink();
    final currentZoom = _state.currentZoom;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: zoomLevels.map((z) {
        final isActive = (currentZoom - z).abs() < 0.3;
        return GestureDetector(
          onTap: () => _setZoom(z),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFE8C547).withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? const Color(0xFFE8C547)
                    : Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '${z == z.truncateToDouble() ? z.toInt() : z}x',
              style: TextStyle(
                color: isActive ? const Color(0xFFE8C547) : Colors.white,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCaptureRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Gallery button
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/gallery'),
            child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.photo_library_outlined,
                  color: Colors.white, size: 22),
            ),
          ),

          // Capture button
          GestureDetector(
            onTap: _capturePhoto,
            child: Container(
              width: 76, height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 12, spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt, color: Colors.black, size: 32),
            ),
          ),

          // Voice / AI button
          GestureDetector(
            onTap: _state.aiState == AiUiState.listening
                ? () async { await _speech?.stop(); _setStatus(AiUiState.idle, null); }
                : _startVoiceCommand,
            child: Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: _state.aiState == AiUiState.listening
                    ? const Color(0xFFE8C547).withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _state.aiState == AiUiState.listening
                      ? const Color(0xFFE8C547)
                      : Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                _state.aiState == AiUiState.listening ? Icons.stop : Icons.mic,
                color: _state.aiState == AiUiState.listening
                    ? const Color(0xFFE8C547)
                    : Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _nsLabel(int ns) {
    final s = ns / 1e9;
    if (s >= 1.0) return '${s.toStringAsFixed(1)}s';
    return '1/${(1.0 / s).round()}';
  }
}
