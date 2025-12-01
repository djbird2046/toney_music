import 'package:flutter/material.dart';

/// Runtime palette that macOS widgets can query from [ThemeData].
@immutable
class MacosColors extends ThemeExtension<MacosColors> {
  const MacosColors({
    required this.brightness,
    required this.background,
    required this.sidebar,
    required this.contentBackground,
    required this.divider,
    required this.innerDivider,
    required this.aiCardBackground,
    required this.aiCardBorder,
    required this.renameBackground,
    required this.renameBorder,
    required this.menuBackground,
    required this.mutedGrey,
    required this.secondaryGrey,
    required this.tertiaryGrey,
    required this.sectionLabel,
    required this.heading,
    required this.iconGrey,
    required this.miniPlayerBackground,
    required this.navSelectedBackground,
    required this.navSelectedShadow,
    required this.accentBlue,
    required this.accentHover,
  });

  final Brightness brightness;
  final Color background;
  final Color sidebar;
  final Color contentBackground;
  final Color divider;
  final Color innerDivider;
  final Color aiCardBackground;
  final Color aiCardBorder;
  final Color renameBackground;
  final Color renameBorder;
  final Color menuBackground;
  final Color mutedGrey;
  final Color secondaryGrey;
  final Color tertiaryGrey;
  final Color sectionLabel;
  final Color heading;
  final Color iconGrey;
  final Color miniPlayerBackground;
  final Color navSelectedBackground;
  final Color navSelectedShadow;
  final Color accentBlue;
  final Color accentHover;

  bool get isDark => brightness == Brightness.dark;

  @override
  MacosColors copyWith({
    Brightness? brightness,
    Color? background,
    Color? sidebar,
    Color? contentBackground,
    Color? divider,
    Color? innerDivider,
    Color? aiCardBackground,
    Color? aiCardBorder,
    Color? renameBackground,
    Color? renameBorder,
    Color? menuBackground,
    Color? mutedGrey,
    Color? secondaryGrey,
    Color? tertiaryGrey,
    Color? sectionLabel,
    Color? heading,
    Color? iconGrey,
    Color? miniPlayerBackground,
    Color? navSelectedBackground,
    Color? navSelectedShadow,
    Color? accentBlue,
    Color? accentHover,
  }) {
    return MacosColors(
      brightness: brightness ?? this.brightness,
      background: background ?? this.background,
      sidebar: sidebar ?? this.sidebar,
      contentBackground: contentBackground ?? this.contentBackground,
      divider: divider ?? this.divider,
      innerDivider: innerDivider ?? this.innerDivider,
      aiCardBackground: aiCardBackground ?? this.aiCardBackground,
      aiCardBorder: aiCardBorder ?? this.aiCardBorder,
      renameBackground: renameBackground ?? this.renameBackground,
      renameBorder: renameBorder ?? this.renameBorder,
      menuBackground: menuBackground ?? this.menuBackground,
      mutedGrey: mutedGrey ?? this.mutedGrey,
      secondaryGrey: secondaryGrey ?? this.secondaryGrey,
      tertiaryGrey: tertiaryGrey ?? this.tertiaryGrey,
      sectionLabel: sectionLabel ?? this.sectionLabel,
      heading: heading ?? this.heading,
      iconGrey: iconGrey ?? this.iconGrey,
      miniPlayerBackground: miniPlayerBackground ?? this.miniPlayerBackground,
      navSelectedBackground:
          navSelectedBackground ?? this.navSelectedBackground,
      navSelectedShadow: navSelectedShadow ?? this.navSelectedShadow,
      accentBlue: accentBlue ?? this.accentBlue,
      accentHover: accentHover ?? this.accentHover,
    );
  }

  @override
  MacosColors lerp(ThemeExtension<MacosColors>? other, double t) {
    if (other is! MacosColors) return this;
    return MacosColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: Color.lerp(background, other.background, t) ?? background,
      sidebar: Color.lerp(sidebar, other.sidebar, t) ?? sidebar,
      contentBackground:
          Color.lerp(contentBackground, other.contentBackground, t) ??
          contentBackground,
      divider: Color.lerp(divider, other.divider, t) ?? divider,
      innerDivider:
          Color.lerp(innerDivider, other.innerDivider, t) ?? innerDivider,
      aiCardBackground:
          Color.lerp(aiCardBackground, other.aiCardBackground, t) ??
          aiCardBackground,
      aiCardBorder:
          Color.lerp(aiCardBorder, other.aiCardBorder, t) ?? aiCardBorder,
      renameBackground:
          Color.lerp(renameBackground, other.renameBackground, t) ??
          renameBackground,
      renameBorder:
          Color.lerp(renameBorder, other.renameBorder, t) ?? renameBorder,
      menuBackground:
          Color.lerp(menuBackground, other.menuBackground, t) ?? menuBackground,
      mutedGrey: Color.lerp(mutedGrey, other.mutedGrey, t) ?? mutedGrey,
      secondaryGrey:
          Color.lerp(secondaryGrey, other.secondaryGrey, t) ?? secondaryGrey,
      tertiaryGrey:
          Color.lerp(tertiaryGrey, other.tertiaryGrey, t) ?? tertiaryGrey,
      sectionLabel:
          Color.lerp(sectionLabel, other.sectionLabel, t) ?? sectionLabel,
      heading: Color.lerp(heading, other.heading, t) ?? heading,
      iconGrey: Color.lerp(iconGrey, other.iconGrey, t) ?? iconGrey,
      miniPlayerBackground:
          Color.lerp(miniPlayerBackground, other.miniPlayerBackground, t) ??
          miniPlayerBackground,
      navSelectedBackground:
          Color.lerp(navSelectedBackground, other.navSelectedBackground, t) ??
          navSelectedBackground,
      navSelectedShadow:
          Color.lerp(navSelectedShadow, other.navSelectedShadow, t) ??
          navSelectedShadow,
      accentBlue: Color.lerp(accentBlue, other.accentBlue, t) ?? accentBlue,
      accentHover: Color.lerp(accentHover, other.accentHover, t) ?? accentHover,
    );
  }
}

extension MacosColorsBuildContext on BuildContext {
  MacosColors get macosColors {
    final colors = Theme.of(this).extension<MacosColors>();
    assert(
      colors != null,
      'MacosColors must be provided through ThemeData.extensions.',
    );
    return colors ?? _fallbackMacosColors;
  }
}

const MacosColors _fallbackMacosColors = MacosColors(
  brightness: Brightness.dark,
  background: Color(0xFF0D0D0D),
  sidebar: Color(0xFF111111),
  contentBackground: Color(0xFF0F0F0F),
  divider: Color(0xFF1F1F1F),
  innerDivider: Color(0xFF202020),
  aiCardBackground: Color(0xFF161616),
  aiCardBorder: Color(0xFF222222),
  renameBackground: Color(0xFF1D1D1D),
  renameBorder: Color(0xFF2E2E2E),
  menuBackground: Color(0xFF1D1D1D),
  mutedGrey: Color(0xFF6F6F6F),
  secondaryGrey: Color(0xFF9E9E9E),
  tertiaryGrey: Color(0xFFB4B4B4),
  sectionLabel: Color(0xFFBDBDBD),
  heading: Color(0xFFD9D9D9),
  iconGrey: Color(0xFFA0A0A0),
  miniPlayerBackground: Color(0xFF121212),
  navSelectedBackground: Color(0xFF1F2A3F),
  navSelectedShadow: Color(0x401F6FEB),
  accentBlue: Color(0xFF4C8DFF),
  accentHover: Color(0x1A4C8DFF),
);
