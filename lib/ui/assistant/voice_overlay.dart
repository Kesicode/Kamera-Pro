/// Voice listening overlay — shown while the mic is active.
library;

import 'package:flutter/material.dart';

class VoiceListeningOverlay extends StatefulWidget {
  const VoiceListeningOverlay({super.key, this.command});
  final String? command;

  @override
  State<VoiceListeningOverlay> createState() => _VoiceListeningOverlayState();
}

class _VoiceListeningOverlayState extends State<VoiceListeningOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing mic icon
              ScaleTransition(
                scale: _pulse,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE8C547).withValues(alpha: 0.15),
                    border: Border.all(
                      color: const Color(0xFFE8C547),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.mic,
                    color: Color(0xFFE8C547),
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Listening...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'SpaceMono',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Describe how you want the photo to look',
                style: TextStyle(
                  color: Color(0xFFAAAAAA),
                  fontSize: 12,
                  fontFamily: 'SpaceMono',
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.command != null) ...[
                const SizedBox(height: 12),
                Text(
                  '"${widget.command}"',
                  style: const TextStyle(
                    color: Color(0xFFE8C547),
                    fontSize: 13,
                    fontFamily: 'SpaceMono',
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
