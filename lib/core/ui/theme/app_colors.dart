// 【主题规格】提供应用颜色及随主题变化的语义色。
// 界面按语义取色，业务逻辑不依赖颜色值。

import 'package:flutter/material.dart';

@immutable
class AppColorSchemeExtension extends ThemeExtension<AppColorSchemeExtension> {
  final Color textPrimary;
  final Color textSecondary;
  final Color success;
  final Color danger;
  final Color separator;
  final Color sidebarBackground;
  final Color controlSurface;
  final Color subtleSurface;
  final Color hoverSurface;
  final Color selectedSurface;
  final Color surface;
  final Color headerBackground;
  final Color activitySurface;
  final Color modalSurface;
  final Color menuSurface;
  final Color mediaHoverOverlay;
  final Color placeholderForeground;
  final Color keyCapBackground;
  final Color keyCapForeground;
  final Color cardShadow;

  const AppColorSchemeExtension({
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.danger,
    required this.separator,
    required this.sidebarBackground,
    required this.controlSurface,
    required this.subtleSurface,
    required this.hoverSurface,
    required this.selectedSurface,
    required this.surface,
    required this.headerBackground,
    required this.activitySurface,
    required this.modalSurface,
    required this.menuSurface,
    required this.mediaHoverOverlay,
    required this.placeholderForeground,
    required this.keyCapBackground,
    required this.keyCapForeground,
    required this.cardShadow,
  });

  @override
  AppColorSchemeExtension copyWith({
    Color? textPrimary,
    Color? textSecondary,
    Color? success,
    Color? danger,
    Color? separator,
    Color? sidebarBackground,
    Color? controlSurface,
    Color? subtleSurface,
    Color? hoverSurface,
    Color? selectedSurface,
    Color? surface,
    Color? headerBackground,
    Color? activitySurface,
    Color? modalSurface,
    Color? menuSurface,
    Color? mediaHoverOverlay,
    Color? placeholderForeground,
    Color? keyCapBackground,
    Color? keyCapForeground,
    Color? cardShadow,
  }) {
    return AppColorSchemeExtension(
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      separator: separator ?? this.separator,
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      controlSurface: controlSurface ?? this.controlSurface,
      subtleSurface: subtleSurface ?? this.subtleSurface,
      hoverSurface: hoverSurface ?? this.hoverSurface,
      selectedSurface: selectedSurface ?? this.selectedSurface,
      surface: surface ?? this.surface,
      headerBackground: headerBackground ?? this.headerBackground,
      activitySurface: activitySurface ?? this.activitySurface,
      modalSurface: modalSurface ?? this.modalSurface,
      menuSurface: menuSurface ?? this.menuSurface,
      mediaHoverOverlay: mediaHoverOverlay ?? this.mediaHoverOverlay,
      placeholderForeground: placeholderForeground ?? this.placeholderForeground,
      keyCapBackground: keyCapBackground ?? this.keyCapBackground,
      keyCapForeground: keyCapForeground ?? this.keyCapForeground,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  AppColorSchemeExtension lerp(covariant AppColorSchemeExtension? other, double t) {
    if (other == null) return this;
    return AppColorSchemeExtension(
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      separator: Color.lerp(separator, other.separator, t)!,
      sidebarBackground: Color.lerp(sidebarBackground, other.sidebarBackground, t)!,
      controlSurface: Color.lerp(controlSurface, other.controlSurface, t)!,
      subtleSurface: Color.lerp(subtleSurface, other.subtleSurface, t)!,
      hoverSurface: Color.lerp(hoverSurface, other.hoverSurface, t)!,
      selectedSurface: Color.lerp(selectedSurface, other.selectedSurface, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      headerBackground: Color.lerp(headerBackground, other.headerBackground, t)!,
      activitySurface: Color.lerp(activitySurface, other.activitySurface, t)!,
      modalSurface: Color.lerp(modalSurface, other.modalSurface, t)!,
      menuSurface: Color.lerp(menuSurface, other.menuSurface, t)!,
      mediaHoverOverlay: Color.lerp(mediaHoverOverlay, other.mediaHoverOverlay, t)!,
      placeholderForeground: Color.lerp(placeholderForeground, other.placeholderForeground, t)!,
      keyCapBackground: Color.lerp(keyCapBackground, other.keyCapBackground, t)!,
      keyCapForeground: Color.lerp(keyCapForeground, other.keyCapForeground, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
    );
  }
}

class AppColors {
  static const primaryLight = Color(0xFF7065A8);
  static const primaryDark = Color(0xFF9186C2);
  static const favoriteLight = Color(0xFFB45F73);
  static const favoriteDark = Color(0xFFD18191);
  static const rating = Color(0xFFFFCC00);

  static AppColorSchemeExtension _scheme(BuildContext context) {
    return Theme.of(context).extension<AppColorSchemeExtension>()!;
  }

  static Color primary(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color favorite(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? favoriteDark : favoriteLight;
  }

  static Color textPrimary(BuildContext context) {
    return _scheme(context).textPrimary;
  }

  static Color textSecondary(BuildContext context) {
    return _scheme(context).textSecondary;
  }

  static Color success(BuildContext context) => _scheme(context).success;

  static Color danger(BuildContext context) => _scheme(context).danger;

  static Color separator(BuildContext context) {
    return _scheme(context).separator;
  }

  static Color sidebarBackground(BuildContext context) {
    return _scheme(context).sidebarBackground;
  }

  static Color controlSurface(BuildContext context) {
    return _scheme(context).controlSurface;
  }

  static Color hoverSurface(BuildContext context) {
    return _scheme(context).hoverSurface;
  }

  static Color selectedSurface(BuildContext context) {
    return _scheme(context).selectedSurface;
  }

  static Color subtleSurface(BuildContext context) => _scheme(context).subtleSurface;

  static Color surface(BuildContext context) => _scheme(context).surface;

  static Color headerBackground(BuildContext context) => _scheme(context).headerBackground;

  static Color activitySurface(BuildContext context) => _scheme(context).activitySurface;

  static Color modalSurface(BuildContext context) => _scheme(context).modalSurface;

  static Color menuSurface(BuildContext context) => _scheme(context).menuSurface;

  static Color mediaHoverOverlay(BuildContext context) => _scheme(context).mediaHoverOverlay;

  static Color placeholderForeground(BuildContext context) => _scheme(context).placeholderForeground;

  static Color keyCapBackground(BuildContext context) => _scheme(context).keyCapBackground;

  static Color keyCapForeground(BuildContext context) => _scheme(context).keyCapForeground;

  static Color cardShadow(BuildContext context) => _scheme(context).cardShadow;
}
