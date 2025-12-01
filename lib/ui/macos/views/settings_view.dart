import 'package:flutter/material.dart';
import 'package:toney_music/l10n/app_localizations.dart';

import '../../../core/localization/app_language.dart';
import '../../../core/theme/app_theme_mode.dart';
import '../macos_colors.dart';

class MacosSettingsView extends StatelessWidget {
  const MacosSettingsView({
    super.key,
    required this.bitPerfectEnabled,
    required this.bitPerfectBusy,
    required this.onToggleBitPerfect,
    required this.selectedLanguage,
    required this.onLanguageChanged,
    required this.selectedTheme,
    required this.onThemeChanged,
  });

  final bool bitPerfectEnabled;
  final bool bitPerfectBusy;
  final ValueChanged<bool> onToggleBitPerfect;
  final AppLanguage selectedLanguage;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final AppThemePreference selectedTheme;
  final ValueChanged<AppThemePreference> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.macosColors;
    return Container(
      color: colors.contentBackground,
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
          Divider(color: colors.innerDivider),
          _SettingsHeader(l10n.settingsAppearanceHeader),
          _ThemeRow(
            title: l10n.settingsThemeLabel,
            description: l10n.settingsThemeDescription,
            value: selectedTheme,
            onChanged: onThemeChanged,
            labels: _ThemeLabels(
              system: l10n.settingsThemeSystemOption,
              light: l10n.settingsThemeLightOption,
              dark: l10n.settingsThemeDarkOption,
            ),
          ),
          Divider(color: colors.innerDivider),
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
          Divider(color: colors.innerDivider),
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
    final colors = context.macosColors;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        label,
        style: TextStyle(
          color: colors.heading,
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
    final colors = context.macosColors;
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged == null || isBusy ? null : onChanged,
      title: Text(
        title,
        style: TextStyle(color: colors.heading, fontWeight: FontWeight.w400),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: colors.mutedGrey, fontWeight: FontWeight.w300),
      ),
      activeColor: colors.accentBlue,
      secondary: isBusy
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(colors.accentBlue),
              ),
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
    final colors = context.macosColors;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(color: colors.heading, fontWeight: FontWeight.w400),
      ),
      subtitle: Text(
        description,
        style: TextStyle(color: colors.mutedGrey, fontWeight: FontWeight.w300),
      ),
      trailing: DropdownButton<AppLanguage>(
        value: value,
        dropdownColor: colors.sidebar,
        borderRadius: BorderRadius.circular(8),
        style: TextStyle(color: colors.heading),
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

class _ThemeLabels {
  const _ThemeLabels({
    required this.system,
    required this.light,
    required this.dark,
  });

  final String system;
  final String light;
  final String dark;
}

class _ThemeRow extends StatelessWidget {
  const _ThemeRow({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.labels,
  });

  final String title;
  final String description;
  final AppThemePreference value;
  final ValueChanged<AppThemePreference> onChanged;
  final _ThemeLabels labels;

  @override
  Widget build(BuildContext context) {
    final colors = context.macosColors;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(color: colors.heading, fontWeight: FontWeight.w400),
      ),
      subtitle: Text(
        description,
        style: TextStyle(color: colors.mutedGrey, fontWeight: FontWeight.w300),
      ),
      trailing: DropdownButton<AppThemePreference>(
        value: value,
        dropdownColor: colors.sidebar,
        borderRadius: BorderRadius.circular(8),
        style: TextStyle(color: colors.heading),
        onChanged: (selection) {
          if (selection != null) {
            onChanged(selection);
          }
        },
        items: [
          DropdownMenuItem(
            value: AppThemePreference.system,
            child: Text(labels.system),
          ),
          DropdownMenuItem(
            value: AppThemePreference.light,
            child: Text(labels.light),
          ),
          DropdownMenuItem(
            value: AppThemePreference.dark,
            child: Text(labels.dark),
          ),
        ],
      ),
    );
  }
}
