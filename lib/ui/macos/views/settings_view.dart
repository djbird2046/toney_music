import 'package:flutter/material.dart';
import 'package:toney_music/l10n/app_localizations.dart';

import '../macos_colors.dart';
import '../../../core/localization/app_language.dart';

class MacosSettingsView extends StatelessWidget {
  const MacosSettingsView({
    super.key,
    required this.bitPerfectEnabled,
    required this.bitPerfectBusy,
    required this.onToggleBitPerfect,
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

  final bool bitPerfectEnabled;
  final bool bitPerfectBusy;
  final ValueChanged<bool> onToggleBitPerfect;
  final AppLanguage selectedLanguage;
  final ValueChanged<AppLanguage> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: MacosColors.contentBackground,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: ListView(
        children: [
          _SettingsHeader(l10n.settingsLanguageLabel),
          _LanguageRow(
            title: l10n.settingsLanguageLabel,
            description: l10n.settingsLanguageDescription,
            value: selectedLanguage,
            onChanged: onLanguageChanged,
            labels: _LanguageLabels(
              system: l10n.settingsLanguageSystemOption,
              chinese: l10n.settingsLanguageChineseOption,
              english: l10n.settingsLanguageEnglishOption,
            ),
          ),
          const Divider(color: MacosColors.innerDivider),
          _SettingsHeader(l10n.settingsPlaybackHeader),
          _ToggleRow(
            title: l10n.settingsBitPerfectTitle,
            subtitle: l10n.settingsBitPerfectSubtitle,
            value: bitPerfectEnabled,
            isBusy: bitPerfectBusy,
            onChanged: onToggleBitPerfect,
          ),
          _ToggleRow(
            title: l10n.settingsAutoSampleRateTitle,
            subtitle: l10n.settingsAutoSampleRateSubtitle,
            value: true,
          ),
          const Divider(color: MacosColors.innerDivider),
          _SettingsHeader(l10n.settingsLibraryHeader),
          _ToggleRow(
            title: l10n.settingsWatchMusicFolderTitle,
            subtitle: l10n.settingsWatchMusicFolderSubtitle,
            value: false,
          ),
          _ToggleRow(
            title: l10n.settingsEnableAiTaggingTitle,
            subtitle: l10n.settingsEnableAiTaggingSubtitle,
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
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w300,
        ),
      ),
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

class _LanguageLabels {
  const _LanguageLabels({
    required this.system,
    required this.chinese,
    required this.english,
  });

  final String system;
  final String chinese;
  final String english;
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.labels,
  });

  final String title;
  final String description;
  final AppLanguage value;
  final ValueChanged<AppLanguage> onChanged;
  final _LanguageLabels labels;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w400,
        ),
      ),
      subtitle: Text(
        description,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w300,
        ),
      ),
      trailing: DropdownButton<AppLanguage>(
        value: value,
        dropdownColor: MacosColors.sidebar,
        borderRadius: BorderRadius.circular(8),
        style: const TextStyle(color: Colors.white),
        onChanged: (selection) {
          if (selection != null) {
            onChanged(selection);
          }
        },
        items: [
          DropdownMenuItem(
            value: AppLanguage.system,
            child: Text(labels.system),
          ),
          DropdownMenuItem(
            value: AppLanguage.chinese,
            child: Text(labels.chinese),
          ),
          DropdownMenuItem(
            value: AppLanguage.english,
            child: Text(labels.english),
          ),
        ],
      ),
    );
  }
}
