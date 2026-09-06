import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';

class AppTheme {
  static final ThemeData lightTheme = lightThemeFor(AppColors.primaryLight);
  static final ThemeData darkTheme = darkThemeFor(AppColors.primaryDark);

  static ThemeData lightThemeFor(Color accentColor) => ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    primaryColor: accentColor,
    fontFamily: _platformFontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: Brightness.light,
      primary: accentColor,
      secondary: accentColor,
    ),
    scaffoldBackgroundColor: const Color(0xFFFFFFFF),
    canvasColor: const Color(0xFFF5F5F7),
    dividerColor: const Color(0xFFE5E5E5),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xFF1D1D1F)),
      titleMedium: TextStyle(color: Color(0xFF1D1D1F)),
    ),
    extensions: <ThemeExtension<dynamic>>[
      AppColorSchemeExtension(
        textPrimary: Color(0xFF1D1D1F),
        textSecondary: Color(0xA61D1D1F),
        success: Color(0xFF2E7D32),
        danger: Color(0xFFD92D20),
        separator: Color(0xFFE5E5EA),
        sidebarBackground: Color(0xFFF5F5F7),
        controlSurface: Color(0x06000000),
        subtleSurface: Color(0x06000000),
        hoverSurface: Color(0x0D1D1D1F),
        selectedSurface: accentColor == AppColors.primaryLight
            ? const Color(0xFFECEAF4)
            : Color.alphaBlend(accentColor.withAlpha(24), Colors.white),
        surface: Colors.white,
        headerBackground: Color(0xD9FFFFFF),
        activitySurface: Color(0xEBFFFFFF),
        modalSurface: Colors.white,
        menuSurface: Colors.white,
        mediaHoverOverlay: Colors.white,
        placeholderForeground: Color(0xFF8E8E93),
        keyCapBackground: Colors.white,
        keyCapForeground: Color(0xFF8E8E93),
        cardShadow: Colors.black,
      ),
    ],
  );

  static ThemeData darkThemeFor(Color accentColor) => ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    primaryColor: accentColor,
    fontFamily: _platformFontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: Brightness.dark,
      primary: accentColor,
      secondary: accentColor,
    ),
    scaffoldBackgroundColor: const Color(0xFF1C1C1E),
    canvasColor: const Color(0xFF2C2C2E),
    dividerColor: const Color(0xFF3A3A3C),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xFFE5E5E7)),
      titleMedium: TextStyle(color: Color(0xFFE5E5E7)),
    ),
    extensions: <ThemeExtension<dynamic>>[
      AppColorSchemeExtension(
        textPrimary: Color(0xFFF5F5F7),
        textSecondary: Color(0xA6F5F5F7),
        success: Color(0xFF63D471),
        danger: Color(0xFFFF6961),
        separator: Color(0xFF3A3A3C),
        sidebarBackground: Color(0xFF202023),
        controlSurface: Color(0x0EFFFFFF),
        subtleSurface: Color(0x0CFFFFFF),
        hoverSurface: Color(0x16F5F5F7),
        selectedSurface: accentColor == AppColors.primaryDark
            ? const Color(0xFF35323F)
            : Color.alphaBlend(accentColor.withAlpha(48), const Color(0xFF2C2C2E)),
        surface: Color(0xFF2C2C2E),
        headerBackground: Color(0xD92C2C2E),
        activitySurface: Color(0xF21F1F22),
        modalSurface: Color(0xFF2C2C2E),
        menuSurface: Color(0xFF2A2A2D),
        mediaHoverOverlay: Colors.black,
        placeholderForeground: Color(0xFF8E8E93),
        keyCapBackground: Color(0xFF4A4A4C),
        keyCapForeground: Color(0xFFE5E5E7),
        cardShadow: Colors.black,
      ),
    ],
  );

  static String? get _platformFontFamily => switch (defaultTargetPlatform) {
    TargetPlatform.windows => 'Microsoft YaHei UI',
    _ => null,
  };
}
