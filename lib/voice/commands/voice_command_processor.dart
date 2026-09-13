/// Routes voice commands to the right AI provider using deterministic-first strategy.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ai/api/photography_ai.dart';
import '../../ai/providers/rule_based_photography_ai.dart';
import '../../ai/providers/gemini_photography_ai.dart';
import '../../photography/intent/photography_intent.dart';
import '../../core/logging/app_logger.dart';
import '../../core/preferences/user_preferences.dart';

class VoiceCommandProcessor {
  const VoiceCommandProcessor({
    required this.ruleBasedAi,
    required this.geminiAi,
    required this.cloudAiEnabled,
  });

  final PhotographyAI ruleBasedAi;
  final PhotographyAI? geminiAi;
  final bool cloudAiEnabled;

  /// 1. Try rule-based (fast, offline).
  /// 2. If confidence < 0.85 AND Gemini available → use Gemini.
  /// 3. Gemini failure → fall back to rule-based.
  Future<PhotographyIntent> process(
    String commandText, {
    PhotographyContext? context,
  }) async {
    log.voice('Processing: "$commandText"');
    final ctx = context ?? const PhotographyContext();

    final ruleResult = await ruleBasedAi.interpretCommand(commandText, ctx);

    if (ruleResult.confidence >= 0.85) {
      log.voice('Rule-based AI used (confidence ${ruleResult.confidence})');
      return ruleResult;
    }

    if (geminiAi != null && cloudAiEnabled) {
      log.ai('Routing to Gemini...');
      try {
        final aiResult = await geminiAi!.interpretCommand(commandText, ctx);
        log.ai('Gemini result: ${aiResult.summary}');
        return aiResult;
      } catch (e, st) {
        log.ai('Gemini failed — fallback to rule-based', error: e, stackTrace: st);
      }
    }

    return ruleResult;
  }
}

final voiceCommandProcessorProvider = Provider<VoiceCommandProcessor>((ref) {
  final ruleAi = ref.watch(ruleBasedAiProvider);
  final geminiAi = ref.watch(geminiAiProvider);
  final prefsAsync = ref.watch(userPreferencesProvider);
  final cloudEnabled = prefsAsync.valueOrNull?.cloudAiEnabled ?? true;

  return VoiceCommandProcessor(
    ruleBasedAi: ruleAi,
    geminiAi: geminiAi,
    cloudAiEnabled: cloudEnabled,
  );
});
