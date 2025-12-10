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
    required this.autoSampleRateEnabled,
    required this.autoSampleRateBusy,
    required this.onToggleAutoSampleRate,
    required this.liteAgentConfigured,
    required this.liteAgentConnected,
    this.liteAgentError,
    required this.liteAgentBaseUrl,
    required this.liteAgentBusy,
    required this.onConfigureLiteAgent,
    required this.onLogoutLiteAgent,
    required this.selectedLanguage,
    required this.onLanguageChanged,
    required this.selectedTheme,
    required this.onThemeChanged,
  });

  final bool bitPerfectEnabled;
  final bool bitPerfectBusy;
  final ValueChanged<bool> onToggleBitPerfect;
  final bool autoSampleRateEnabled;
  final bool autoSampleRateBusy;
  final ValueChanged<bool> onToggleAutoSampleRate;
  final bool liteAgentConfigured;
  final bool liteAgentConnected;
  final String? liteAgentError;
  final String? liteAgentBaseUrl;
  final bool liteAgentBusy;
  final VoidCallback onConfigureLiteAgent;
  final VoidCallback onLogoutLiteAgent;
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
          _SettingsHeader(l10n.settingsAppearanceHeader),
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
            value: autoSampleRateEnabled,
            isBusy: autoSampleRateBusy,
            onChanged: bitPerfectEnabled ? null : onToggleAutoSampleRate,
          ),
          Divider(color: colors.innerDivider),
          _SettingsHeader(l10n.settingsAiHeader),
          _LiteAgentRow(
            isBusy: liteAgentBusy,
            isConnected: liteAgentConnected,
            baseUrl: liteAgentConfigured ? liteAgentBaseUrl ?? '' : '',
            errorMessage: liteAgentError,
            onConfigure: onConfigureLiteAgent,
            onLogout: onLogoutLiteAgent,
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

class _LiteAgentRow extends StatelessWidget {
  const _LiteAgentRow({
    required this.isBusy,
    required this.isConnected,
    required this.baseUrl,
    required this.errorMessage,
    required this.onConfigure,
    required this.onLogout,
  });

  final bool isBusy;
  final bool isConnected;
  final String baseUrl;
  final String? errorMessage;
  final VoidCallback onConfigure;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final colors = context.macosColors;
    final l10n = AppLocalizations.of(context)!;
    final hasConfig = baseUrl.isNotEmpty;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        l10n.settingsLiteAgentTitle,
        style: TextStyle(color: colors.heading, fontWeight: FontWeight.w400),
      ),
      subtitle: isBusy
          ? Row(
              children: [
                SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colors.accentBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.settingsLiteAgentChecking,
                  style: TextStyle(
                    color: colors.mutedGrey,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            )
          : Text(
              hasConfig
                  ? (isConnected
                        ? l10n.settingsLiteAgentConnected(baseUrl)
                        : l10n.settingsLiteAgentConnectionFailed(
                            errorMessage ?? '',
                          ))
                  : l10n.settingsLiteAgentNotConfigured,
              style: TextStyle(
                color: colors.mutedGrey,
                fontWeight: FontWeight.w300,
              ),
            ),
      trailing: TextButton(
        onPressed: isBusy ? null : (hasConfig ? onLogout : onConfigure),
        child: Text(
          hasConfig
              ? l10n.settingsLiteAgentLogout
              : l10n.settingsLiteAgentConfigure,
          style: TextStyle(color: colors.accentBlue),
        ),
      ),
    );
  }
}
