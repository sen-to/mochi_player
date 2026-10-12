import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/settings/application/theme_provider.dart';
import 'package:mochi_player/l10n/l10n.dart';

class ThemeModePicker extends StatelessWidget {
  const ThemeModePicker({super.key, required this.value, required this.accentColor, required this.onChanged});

  final ThemeMode value;
  final Color accentColor;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    const modes = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];
    const previewWidth = 220.0;
    const previewGap = 48.0;
    final previews = modes
        .map(
          (mode) => SizedBox(
            width: previewWidth,
            child: _ThemePreviewCard(
              mode: mode,
              selected: mode == value,
              accentColor: accentColor,
              onTap: () => onChanged(mode),
            ),
          ),
        )
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= previewWidth * 3 + previewGap * 2) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                previews[0],
                const SizedBox(width: previewGap),
                previews[1],
                const SizedBox(width: previewGap),
                previews[2],
              ],
            );
          }
          return Wrap(spacing: AppSpacing.md, runSpacing: AppSpacing.md, children: previews);
        },
      ),
    );
  }
}

class AccentColorPicker extends StatelessWidget {
  const AccentColorPicker({super.key, required this.value, required this.onChanged});

  final AppAccentColor value;
  final ValueChanged<AppAccentColor> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: AppAccentColor.values
          .map(
            (accent) => Padding(
              padding: const EdgeInsets.only(left: AppSpacing.md),
              child: Tooltip(
                message: _accentLabel(context, accent),
                child: InkWell(
                  onTap: () => onChanged(accent),
                  borderRadius: BorderRadius.circular(22),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(180), width: value == accent ? 3 : 0),
                      boxShadow: value == accent ? [BoxShadow(color: accent.color.withAlpha(86), blurRadius: 8)] : null,
                    ),
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: value == accent ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({required this.mode, required this.selected, required this.accentColor, required this.onTap});

  final ThemeMode mode;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  String _label(BuildContext context) => switch (mode) {
    ThemeMode.light => context.l10n.themeLight,
    ThemeMode.dark => context.l10n.themeDark,
    ThemeMode.system => context.l10n.languageSystem,
  };

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? accentColor : AppColors.separator(context);
    return Semantics(
      button: true,
      selected: selected,
      label: context.l10n.themeLabel(_label(context)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.control),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AspectRatio(
              aspectRatio: 1.6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.control),
                  border: Border.all(color: borderColor, width: selected ? 2 : 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.control - 1),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: SvgPicture.asset(switch (mode) {
                          ThemeMode.light => 'assets/theme_previews/light.svg',
                          ThemeMode.dark => 'assets/theme_previews/dark.svg',
                          ThemeMode.system => 'assets/theme_previews/system.svg',
                        }, fit: BoxFit.cover),
                      ),
                      if (selected)
                        Positioned(
                          right: AppSpacing.sm,
                          bottom: AppSpacing.sm,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                            child: const SizedBox(
                              width: 24,
                              height: 24,
                              child: Icon(Icons.check_rounded, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _label(context),
              style: TextStyle(
                color: selected ? accentColor : AppColors.textSecondary(context),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _accentLabel(BuildContext context, AppAccentColor color) => switch (color) {
  AppAccentColor.blue => context.l10n.accentBlue,
  AppAccentColor.green => context.l10n.accentGreen,
  AppAccentColor.purple => context.l10n.accentPurple,
  AppAccentColor.orange => context.l10n.accentOrange,
  AppAccentColor.red => context.l10n.accentRed,
};
