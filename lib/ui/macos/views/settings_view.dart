import 'package:flutter/material.dart';

import '../macos_colors.dart';

class MacosSettingsView extends StatelessWidget {
  const MacosSettingsView({
    super.key,
    required this.bitPerfectEnabled,
    required this.bitPerfectBusy,
    required this.onToggleBitPerfect,
  });

  final bool bitPerfectEnabled;
  final bool bitPerfectBusy;
  final ValueChanged<bool> onToggleBitPerfect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MacosColors.contentBackground,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: ListView(
        children: [
          const _SettingsHeader('Playback'),
          _ToggleRow(
            title: 'Bit-perfect mode',
            subtitle: 'Bypass system DSP for CoreAudio output',
            value: bitPerfectEnabled,
            isBusy: bitPerfectBusy,
            onChanged: onToggleBitPerfect,
          ),
          const _ToggleRow(
            title: 'Auto sample-rate switching',
            subtitle: 'Follow source file sample rate on device output',
            value: true,
          ),
          const Divider(color: MacosColors.innerDivider),
          const _SettingsHeader('Library'),
          const _ToggleRow(
            title: 'Watch Music folder',
            subtitle: 'Automatically import new files inside ~/Music',
            value: false,
          ),
          const _ToggleRow(
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
          fontWeight: FontWeight.w400,
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
    this.onChanged,
    this.isBusy = false,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged == null || isBusy ? null : onChanged,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
        ),
      ),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w300)),
      secondary: isBusy
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
    );
  }
}
