/// Debug screen — shows live camera parameters, AI state, and logs.
library;

import 'package:flutter/material.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Debug',
            style: TextStyle(fontFamily: 'SpaceMono', fontSize: 16)),
        backgroundColor: const Color(0xFF0A0A0A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DebugSection(title: 'CAMERA STATE'),
            _DebugRow(label: 'Camera ID', value: 'Back (0)'),
            _DebugRow(label: 'Session', value: 'Ready'),
            SizedBox(height: 24),
            _DebugSection(title: 'PARAMETERS'),
            _DebugRow(label: 'ISO', value: 'AUTO'),
            _DebugRow(label: 'Shutter', value: 'AUTO'),
            _DebugRow(label: 'WB', value: 'AUTO'),
            _DebugRow(label: 'Zoom', value: '1.0x'),
            _DebugRow(label: 'Flash', value: 'OFF'),
            SizedBox(height: 24),
            _DebugSection(title: 'AI STATE'),
            _DebugRow(label: 'Rule AI', value: 'Ready'),
            _DebugRow(label: 'Gemini AI', value: 'Ready (key loaded)'),
            _DebugRow(label: 'Last command', value: '—'),
            _DebugRow(label: 'Confidence', value: '—'),
          ],
        ),
      ),
    );
  }
}

class _DebugSection extends StatelessWidget {
  const _DebugSection({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title,
        style: const TextStyle(
          color: Color(0xFFE8C547),
          fontSize: 10,
          letterSpacing: 1.5,
          fontFamily: 'SpaceMono',
        )),
  );
}

class _DebugRow extends StatelessWidget {
  const _DebugRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: const TextStyle(
                color: Colors.white38,
                fontFamily: 'SpaceMono',
                fontSize: 11,
              )),
        ),
        Text(value,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'SpaceMono',
              fontSize: 11,
            )),
      ],
    ),
  );
}
