/// Android on-device speech recognizer using the speech_to_text package.
library;

import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/logging/app_logger.dart';
import 'speech_recognizer.dart';

class AndroidSpeechRecognizer implements SpeechRecognizer {
  AndroidSpeechRecognizer() : _speech = stt.SpeechToText();

  final stt.SpeechToText _speech;
  bool _initialized = false;

  @override
  bool get isAvailable => _initialized && _speech.isAvailable;

  @override
  Future<bool> initialize() async {
    if (_initialized) return true;
    log.voice('Initializing SpeechRecognizer...');
    _initialized = await _speech.initialize(
      onError: (e) => log.voice('Speech error: $e'),
      onStatus: (s) => log.voice('Speech status: $s'),
    );
    log.voice('SpeechRecognizer ready: $_initialized');
    return _initialized;
  }

  @override
  Stream<String> listenStream() async* {
    if (!_initialized) await initialize();
    final buffer = <String>[];
    bool done = false;

    await _speech.listen(
      onResult: (r) {
        if (r.recognizedWords.isNotEmpty) buffer.add(r.recognizedWords);
        if (r.finalResult) done = true;
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
      ),
    );

    while (!done) {
      while (buffer.isNotEmpty) {
        yield buffer.removeAt(0);
      }
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  Future<SpeechResult> listenOnce({Duration? timeout}) async {
    if (!_initialized) {
      final ok = await initialize();
      if (!ok) return const SpeechError('Speech recognition unavailable.');
    }
    if (!_speech.isAvailable) {
      return const SpeechError('Speech recognizer not available.');
    }

    log.voice('Listening...');
    String? finalText;
    bool done = false;

    await _speech.listen(
      onResult: (r) {
        if (r.finalResult && r.recognizedWords.isNotEmpty) {
          finalText = r.recognizedWords;
          done = true;
        }
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        cancelOnError: true,
        partialResults: false,
        listenFor: timeout ?? const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
      ),
    );

    // Wait for done or timeout
    final deadline = DateTime.now().add(
      (timeout ?? const Duration(seconds: 10)) + const Duration(seconds: 2),
    );
    while (!done && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    await _speech.stop();

    if (finalText == null || finalText!.isEmpty) {
      log.voice('No speech detected');
      return const SpeechEmpty();
    }
    log.voice('Recognized: "$finalText"');
    return SpeechSuccess(finalText!);
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> dispose() => _speech.cancel();
}

final speechRecognizerProvider = Provider<SpeechRecognizer>(
  (_) => AndroidSpeechRecognizer(),
);
