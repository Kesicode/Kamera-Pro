/// Horizontal presets bar shown at the bottom of the camera screen.
library;

import 'package:flutter/material.dart';
import '../../photography/presets/preset.dart';

class PresetsBar extends StatelessWidget {
  const PresetsBar({
    super.key,
    required this.onPresetSelected,
    this.selectedPreset,
  });

  final void Function(Preset preset) onPresetSelected;
  final Preset? selectedPreset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: PresetLibrary.all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final preset = PresetLibrary.all[i];
          final isSelected = selectedPreset?.name == preset.name;
          return GestureDetector(
            onTap: () => onPresetSelected(preset),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFE8C547).withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFE8C547)
                      : Colors.white.withValues(alpha: 0.25),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(preset.icon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    preset.name,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFFE8C547)
                          : Colors.white,
                      fontSize: 12,
                      fontFamily: 'SpaceMono',
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
