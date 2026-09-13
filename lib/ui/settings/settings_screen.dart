/// Settings screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/preferences/user_preferences.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(userPreferencesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontFamily: 'SpaceMono', fontSize: 16)),
        backgroundColor: const Color(0xFF0A0A0A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: prefsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFE8C547)),
        ),
        error: (e, _) => Center(
          child: Text('Settings unavailable\n$e',
              style: const TextStyle(color: Colors.white54),
              textAlign: TextAlign.center),
        ),
        data: (prefs) => ListView(
          children: [
            _section('AI & VOICE'),
            _toggle(
              label: 'AI Assistance',
              subtitle: 'Use Gemini AI for complex commands',
              value: prefs.aiEnabled,
              onChanged: (v) {
                prefs.aiEnabled = v;
              },
            ),
            _toggle(
              label: 'Cloud AI',
              subtitle: 'Route complex commands to Gemini',
              value: prefs.cloudAiEnabled,
              onChanged: (v) { prefs.cloudAiEnabled = v; },
            ),
            _toggle(
              label: 'Educational Mode',
              subtitle: 'Show "Why these settings?" explanations',
              value: prefs.educationalMode,
              onChanged: (v) { prefs.educationalMode = v; },
            ),
            _section('DEVELOPER'),
            _toggle(
              label: 'Debug Mode',
              subtitle: 'Show parameter values and logs',
              value: prefs.debugMode,
              onChanged: (v) { prefs.debugMode = v; },
            ),
            if (prefs.debugMode)
              ListTile(
                title: const Text('Open Debug Screen',
                    style: TextStyle(color: Colors.white, fontFamily: 'SpaceMono', fontSize: 13)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                onTap: () => Navigator.pushNamed(context, '/debug'),
              ),
            _section('ABOUT'),
            _info('Version', '1.0.0-mvp'),
            _info('AI Model', 'gemini-2.0-flash'),
            _info('Camera Engine', 'camerawesome 2.x'),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 6),
    child: Text(title,
        style: const TextStyle(
          color: Color(0xFFE8C547),
          fontSize: 10,
          letterSpacing: 1.5,
          fontFamily: 'SpaceMono',
        )),
  );

  Widget _toggle({
    required String label,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
  }) =>
      SwitchListTile(
        title: Text(label,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'SpaceMono',
              fontSize: 13,
            )),
        subtitle: Text(subtitle,
            style: const TextStyle(
              color: Colors.white38,
              fontFamily: 'SpaceMono',
              fontSize: 11,
            )),
        value: value,
        activeThumbColor: const Color(0xFFE8C547),
        onChanged: onChanged,
      );

  Widget _info(String label, String value) => ListTile(
    title: Text(label,
        style: const TextStyle(
          color: Colors.white54,
          fontFamily: 'SpaceMono',
          fontSize: 12,
        )),
    trailing: Text(value,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'SpaceMono',
          fontSize: 12,
        )),
  );
}
