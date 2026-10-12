import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/components/overlay/app_dropdown.dart';
import 'package:mochi_player/core/ui/theme/app_colors.dart';
import 'package:mochi_player/core/ui/theme/app_control_metrics.dart';
import 'package:mochi_player/core/ui/theme/app_icons.dart';
import 'package:mochi_player/core/ui/theme/app_radii.dart';
import 'package:mochi_player/core/ui/theme/app_spacing.dart';
import 'package:mochi_player/core/ui/theme/app_typography.dart';
import 'package:mochi_player/l10n/l10n.dart';

class AppSelectOption<T> {
  final T value;
  final String label;

  const AppSelectOption({required this.value, required this.label});
}

class AppSelect<T> extends StatelessWidget {
  static const double _height = 32;

  final T? value;
  final String? placeholder;
  final List<AppSelectOption<T>> options;
  final ValueChanged<T>? onChanged;

  const AppSelect({super.key, required this.value, required this.options, this.onChanged, this.placeholder});

  @override
  Widget build(BuildContext context) {
    final selectedLabel = _labelFor(value) ?? placeholder ?? context.l10n.select;
    final foreground = AppColors.textPrimary(context).withAlpha(230);
    final isEnabled = onChanged != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final menuWidth = constraints.hasBoundedWidth ? constraints.maxWidth : 160.0;
        return AnimatedOpacity(
          duration: AppControlMetrics.stateAnimationDuration,
          opacity: isEnabled ? 1 : 0.5,
          child: AppDropdown<T>(
            menuWidth: menuWidth,
            trigger: SizedBox(
              height: _height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.controlSurface(context),
                  borderRadius: BorderRadius.circular(AppRadii.control),
                  border: Border.all(color: AppColors.separator(context)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.compact),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          selectedLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.controlLabel.copyWith(color: foreground, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(AppIcons.chevronDown, size: 13, color: foreground),
                    ],
                  ),
                ),
              ),
            ),
            selectedValue: value,
            onSelected: onChanged,
            options: options.map((option) => AppDropdownOption<T>(value: option.value, label: option.label)).toList(),
          ),
        );
      },
    );
  }

  String? _labelFor(T? value) {
    if (value == null) return null;
    for (final option in options) {
      if (option.value == value) return option.label;
    }
    return null;
  }
}
