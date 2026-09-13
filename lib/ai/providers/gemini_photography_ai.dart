/// Gemini-backed photography AI provider.
/// SECURITY: All AI output flows through AiOutputValidator before becoming PhotographyIntent.
library;

import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/photography_ai.dart';
import '../validation/ai_output_validator.dart';
import '../../photography/intent/photography_intent.dart';
import '../../core/logging/app_logger.dart';

const _systemPrompt = '''
You are a photography expert for Kamera Pro. Parse the user's natural-language command into JSON only.
Return ONLY valid JSON — no markdown, no explanation.

Schema:
{
  "captureType": "photo"|"video"|"slowMotion"|"timelapse"|"burst",
  "scene": "portrait"|"landscape"|"night"|"food"|"architecture"|"macro"|"sports"|"lowLight"|"sunset"|"moon"|"stars"|"document"|"product"|"street"|"wildlife"|"general"|null,
  "style": "cinematic"|"vintage"|"film"|"blackAndWhite"|"natural"|"bright"|"moody"|"dramatic"|"soft"|"highContrast"|"cool"|"warm"|"none"|null,
  "subjectMotion": "stationary"|"walking"|"running"|"vehicle"|"animal"|"fastObject"|"unknown"|null,
  "lightingIntent": "bright"|"dark"|"warm"|"cool"|"natural"|"dramatic"|"lowKey"|"highKey"|"auto"|null,
  "composition": "closeUp"|"mediumShot"|"wideShot"|"centered"|"ruleOfThirds"|"overhead"|"lowAngle"|"highAngle"|"none"|null,
  "exposurePreference": "balanced"|"bright"|"dark"|"faceExposed"|"highlightProtected"|"auto"|null,
  "focusPreference": "subject"|"face"|"eyes"|"background"|"infinity"|"manual"|"auto"|null,
  "flashIntent": "off"|"on"|"auto"|"fill"|null,
  "confidence": <0.0-1.0>,
  "conflictWarnings": ["..."],
  "userOverrides": {
    "iso": <int>|null,
    "shutter": "1/250"|null,
    "whiteBalanceK": <int>|null,
    "zoom": <number>|null,
    "exposureCompensation": <number>|null
  }
}
''';

class GeminiPhotographyAI implements PhotographyAI {
  GeminiPhotographyAI(this._model, this._validator);

  final GenerativeModel _model;
  final AiOutputValidator _validator;

  @override
  Future<PhotographyIntent> interpretCommand(
    String commandText,
    PhotographyContext context,
  ) async {
    log.ai('GeminiAI: "$commandText"');

    final ctx = context.toMap().isNotEmpty
        ? '\n\nContext: ${jsonEncode(context.toMap())}'
        : '';

    final response = await _model.generateContent([
      Content.text('$commandText$ctx'),
    ]);

    final rawText = response.text;
    if (rawText == null || rawText.isEmpty) {
      throw Exception('Gemini returned empty response');
    }

    log.ai('Gemini raw: $rawText');

    final cleaned = rawText
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    late Map<String, dynamic> json;
    try {
      json = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Gemini returned invalid JSON: $e');
    }

    final result = _validator.validate(json, commandText);
    return result.fold(
      (intent) => intent,
      (error) => throw Exception('Validation failed: $error'),
    );
  }
}

GenerativeModel? _buildModel() {
  try {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      log.warning('GEMINI_API_KEY not set — AI disabled');
      return null;
    }
    return GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: key,
      systemInstruction: Content.text(_systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.1,
        maxOutputTokens: 512,
        responseMimeType: 'application/json',
      ),
    );
  } catch (e) {
    log.warning('Failed to build Gemini model: $e');
    return null;
  }
}

final geminiAiProvider = Provider<PhotographyAI?>((ref) {
  final model = _buildModel();
  if (model == null) return null;
  return GeminiPhotographyAI(model, const AiOutputValidator());
});
