/// Speech recognizer interface for Kamera Pro.
library;

/// The result of a speech recognition attempt.
sealed class SpeechResult {
  const SpeechResult();
}

/// Successful transcription.
final class SpeechSuccess extends SpeechResult {
  const SpeechSuccess(this.text, {this.confidence = 1.0});
  final String text;
  final double confidence;

  @override
  String toString() => 'SpeechSuccess("$text", conf=$confidence)';
}

/// Recognition produced no text.
final class SpeechEmpty extends SpeechResult {
  const SpeechEmpty();
}

/// Recognition failed.
final class SpeechError extends SpeechResult {
  const SpeechError(this.message, {this.isPermissionDenied = false});
  final String message;
  final bool isPermissionDenied;

  @override
  String toString() => 'SpeechError($message)';
}

/// Abstract speech recognizer interface.
abstract interface class SpeechRecognizer {
  Future<bool> initialize();
  bool get isAvailable;
  Stream<String> listenStream();
  Future<SpeechResult> listenOnce({Duration? timeout});
  Future<void> stop();
  Future<void> dispose();
}
