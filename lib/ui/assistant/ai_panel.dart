/// AI results panel — shows intent, parameters, and educational explanation.
library;

import 'package:flutter/material.dart';
import '../../photography/intent/photography_intent.dart';
import '../../photography/parameters/camera_parameter_plan.dart';

class AiPanel extends StatelessWidget {
  const AiPanel({
    super.key,
    required this.intent,
    required this.plan,
    required this.onClose,
  });

  final PhotographyIntent? intent;
  final CameraParameterPlan plan;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome,
                    color: Color(0xFFE8C547), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    intent?.summary ?? 'AI Suggested Settings',
                    style: const TextStyle(
                      color: Color(0xFFE8C547),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SpaceMono',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Parameter summary
          if (plan.parameterSummary.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                plan.parameterSummary,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'SpaceMono',
                ),
              ),
            ),

          // Educational explanation
          if (plan.educationalExplanation != null &&
              plan.educationalExplanation!.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'WHY THESE SETTINGS?',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 9,
                  letterSpacing: 1.5,
                  fontFamily: 'SpaceMono',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                plan.educationalExplanation!,
                style: const TextStyle(
                  color: Color(0xFFCCCCCC),
                  fontSize: 11,
                  fontFamily: 'SpaceMono',
                  height: 1.6,
                ),
              ),
            ),
          ],

          // Rejection warnings
          if (plan.hasRejections) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: plan.rejectedParameters.map((r) {
                  return Text(
                    '⚠ ${r.userMessage ?? r.reason}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontFamily: 'SpaceMono',
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
