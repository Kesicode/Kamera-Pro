/// Manual camera controls panel with sliders for ISO, shutter, WB, etc.
library;

import 'package:flutter/material.dart';
import '../../camera/capabilities/camera_capabilities.dart';
import '../../photography/parameters/camera_parameter_plan.dart';

class ManualControlsPanel extends StatelessWidget {
  const ManualControlsPanel({
    super.key,
    required this.capabilities,
    required this.onParameterChanged,
    required this.onClose,
    this.currentPlan,
  });

  final CameraCapabilities capabilities;
  final CameraParameterPlan? currentPlan;
  final void Function(String param, dynamic value) onParameterChanged;
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
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.tune, color: Color(0xFFE8C547), size: 16),
                const SizedBox(width: 8),
                const Text('MANUAL CONTROLS',
                    style: TextStyle(
                      color: Color(0xFFE8C547),
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontFamily: 'SpaceMono',
                    )),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF2A2A2A), height: 1),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Zoom
                if (capabilities.supportsZoom && capabilities.zoomRange != null)
                  _buildSlider(
                    label: 'ZOOM',
                    value: currentPlan?.zoom?.value ?? 1.0,
                    min: capabilities.zoomRange!.min.toDouble(),
                    max: capabilities.zoomRange!.max.toDouble(),
                    divisions: ((capabilities.zoomRange!.max - capabilities.zoomRange!.min) * 10).round(),
                    displayValue: '${(currentPlan?.zoom?.value ?? 1.0).toStringAsFixed(1)}x',
                    onChanged: (v) => onParameterChanged('zoom', v),
                  ),

                // Flash toggle
                if (capabilities.supportsFlash)
                  _buildToggle(
                    label: 'FLASH',
                    value: currentPlan?.flash?.value ?? false,
                    onChanged: (v) => onParameterChanged('flash', v),
                  ),

                // EV compensation
                if (capabilities.exposureCompensationRange != null)
                  _buildSlider(
                    label: 'EV',
                    value: currentPlan?.exposureCompensation?.value ?? 0.0,
                    min: capabilities.exposureCompensationRange!.min.toDouble(),
                    max: capabilities.exposureCompensationRange!.max.toDouble(),
                    divisions: 8,
                    displayValue:
                        '${(currentPlan?.exposureCompensation?.value ?? 0).toStringAsFixed(1)} EV',
                    onChanged: (v) => onParameterChanged('ev', v),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required void Function(double) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 9,
                    letterSpacing: 1.2,
                    fontFamily: 'SpaceMono',
                  )),
              Text(displayValue,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontFamily: 'SpaceMono',
                  )),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions > 0 ? divisions : null,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildToggle({
    required String label,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 9,
                letterSpacing: 1.2,
                fontFamily: 'SpaceMono',
              )),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFFE8C547),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
