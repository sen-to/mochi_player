import 'package:mochi_player/core/domain/media/watch_progress_policy.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/formatters/media_format.dart';
import 'package:mochi_player/l10n/l10n.dart';

/// Builds the title and detail lines used to present a media file.
abstract final class MediaFileLabels {
  static String versionTitle(MediaFile file) {
    final parsedLabel = file.versionLabel?.trim();
    if (parsedLabel != null && parsedLabel.isNotEmpty) return parsedLabel;

    final parts = [
      file.quality,
      file.videoCodec,
      if (file.isHdr) file.hdrFormat ?? 'HDR',
    ].whereType<String>().where((part) => part.trim().isNotEmpty).toSet();
    return parts.isEmpty ? file.fileName : parts.join(' • ');
  }

  static String versionSubtitle(
    MediaFile file, {
    required AppLocalizations l10n,
    bool includeContainer = true,
    bool includeResumePosition = false,
  }) {
    final parts = <String>[];
    final codec = file.audioCodec;
    if (codec != null && codec.isNotEmpty) parts.add(codec);

    final channels = file.audioChannels;
    if (channels != null && channels.isNotEmpty) parts.add(channels);

    final container = file.container;
    if (includeContainer && container != null && container.isNotEmpty) {
      parts.add(container.toUpperCase());
    }
    if (file.size > 0) parts.add(MediaFormat.fileSize(file.size, locale: l10n.localeName));
    if (includeResumePosition &&
        file.position > 0 &&
        file.duration > 0 &&
        file.progress < WatchProgressPolicy.completionThreshold) {
      parts.add(l10n.resumeFrom(MediaFormat.clockDuration(Duration(milliseconds: file.position))));
    }
    return parts.isEmpty ? file.fileName : parts.join(' • ');
  }

  static String playableVersionTitle(MediaFile file) {
    var title = file.versionLabel?.trim() ?? '';
    if (title.isEmpty) {
      return file.quality.isNotEmpty ? file.quality : file.fileName;
    }

    final technicalParts = [
      _formattedCodec(file.videoCodec),
      _formattedCodec(file.audioCodec),
      _formattedHdr(file.hdrFormat),
    ].whereType<String>().where((part) => part.isNotEmpty);
    for (final part in technicalParts) {
      title = title.replaceAll(RegExp(RegExp.escape(part), caseSensitive: false), ' ');
    }
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    return title.isEmpty ? (file.quality.isNotEmpty ? file.quality : file.fileName) : title;
  }

  static String playableVersionDetails(MediaFile file, {required AppLocalizations l10n}) {
    final parts = <String>[];
    final videoParts = [
      _formattedCodec(file.videoCodec),
      _formattedHdr(file.hdrFormat),
    ].whereType<String>().where((part) => part.isNotEmpty).toList();
    if (videoParts.isNotEmpty) parts.add(videoParts.join(' '));

    final audioParts = [
      _formattedCodec(file.audioCodec),
      file.audioChannels,
    ].whereType<String>().where((part) => part.isNotEmpty).toList();
    if (audioParts.isNotEmpty) parts.add(audioParts.join(' '));

    final container = file.container;
    if (container != null && container.isNotEmpty) {
      parts.add(container.toUpperCase());
    }
    if (file.size > 0) parts.add(MediaFormat.fileSize(file.size, locale: l10n.localeName));
    return parts.isEmpty ? file.fileName : parts.join(' · ');
  }

  static String? _formattedHdr(String? value) {
    if (value == null || value.isEmpty) return null;
    return switch (value.toLowerCase()) {
      'dolby_vision' => 'Dolby Vision',
      'hdr10plus' => 'HDR10+',
      _ => value.replaceAll('_', ' ').toUpperCase(),
    };
  }

  static String? _formattedCodec(String? value) {
    if (value == null || value.isEmpty) return null;
    return value.toUpperCase();
  }
}
