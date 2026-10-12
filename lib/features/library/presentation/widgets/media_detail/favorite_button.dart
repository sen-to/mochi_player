import 'package:flutter/material.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/application/media_library_provider.dart';
import 'package:mochi_player/features/library/presentation/widgets/library_query.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:provider/provider.dart';

class FavoriteButton extends StatelessWidget {
  final String tmdbId;
  final Color? overrideColor;
  final bool showLabel;

  const FavoriteButton({super.key, required this.tmdbId, this.overrideColor, this.showLabel = false});

  @override
  Widget build(BuildContext context) {
    return LibraryQuery<List<MediaFile>>(
      queryKey: tmdbId,
      query: (r) => r.watchVersions(tmdbId),
      initialData: const [],
      builder: (context, files) => _buildButton(context, files.any((file) => file.isFavorite)),
    );
  }

  Widget _buildButton(BuildContext context, bool isFavorite) {
    final usesOverlayAppearance = overrideColor != null;
    final favoriteColor = AppColors.favorite(context);
    final icon = isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded;
    void toggleFavorite() {
      context.read<MediaLibraryProvider>().setFavorite(tmdbId, isFavorite: !isFavorite);
    }

    if (showLabel) {
      return AppButton(
        onPressed: toggleFavorite,
        icon: icon,
        label: isFavorite ? context.l10n.favorited : context.l10n.addFavorite,
        variant: AppButtonVariant.secondary,
        appearance: usesOverlayAppearance ? AppAppearance.overlay : AppAppearance.standard,
        selected: isFavorite,
        accentColor: favoriteColor,
        size: AppButtonSize.regular,
      );
    }

    return AppButton.icon(
      onPressed: toggleFavorite,
      icon: icon,
      tooltip: isFavorite ? context.l10n.removeFavorite : context.l10n.addFavorite,
      selected: isFavorite,
      appearance: usesOverlayAppearance ? AppAppearance.overlay : AppAppearance.standard,
      accentColor: favoriteColor,
      size: AppButtonSize.large,
    );
  }
}
