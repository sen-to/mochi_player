import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/core/ui/theme/app_theme.dart';

void main() {
  test('uses muted primary and selected-surface colors', () {
    expect(AppTheme.lightTheme.colorScheme.primary, AppColors.primaryLight);
    expect(AppTheme.darkTheme.colorScheme.primary, AppColors.primaryDark);

    final lightColors = AppTheme.lightTheme.extension<AppColorSchemeExtension>()!;
    final darkColors = AppTheme.darkTheme.extension<AppColorSchemeExtension>()!;
    expect(lightColors.selectedSurface, const Color(0xFFECEAF4));
    expect(darkColors.selectedSurface, const Color(0xFF35323F));
    expect(lightColors.controlSurface, const Color(0x06000000));
    expect(darkColors.controlSurface, const Color(0x0EFFFFFF));
  });

  test('derives the theme primary and selection surface from the accent color', () {
    const accent = Color(0xFF43B649);

    final theme = AppTheme.lightThemeFor(accent);
    final colors = theme.extension<AppColorSchemeExtension>()!;

    expect(theme.colorScheme.primary, accent);
    expect(colors.selectedSurface, isNot(const Color(0xFFECEAF4)));
  });
}
