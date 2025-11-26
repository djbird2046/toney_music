import 'package:flutter/material.dart';

import '../macos_colors.dart';

class MacosSettingsView extends StatelessWidget {
  const MacosSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MacosColors.contentBackground,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: ListView(
        children: const [
          _SettingsHeader('Playback'),
          _ToggleRow(
            title: 'Bit-perfect mode',
            subtitle: 'Bypass system DSP for CoreAudio output',
            value: true,
          ),
          _ToggleRow(
            title: 'Auto sample-rate switching',
            subtitle: 'Follow source file sample rate on device output',
            value: true,
          ),
          Divider(color: MacosColors.innerDivider),
          _SettingsHeader('Library'),
          _ToggleRow(
            title: 'Watch Music folder',
            subtitle: 'Automatically import new files inside ~/Music',
            value: false,
          ),
          _ToggleRow(
            title: 'Enable AI tagging',
            subtitle: 'Send fingerprints to on-device model',
            value: true,
          ),
        ],
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final String title;
  final String subtitle;
  final bool value;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: (_) {},
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500)),
    );
  }
}
