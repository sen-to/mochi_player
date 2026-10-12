/// Track identities include their origin: an external path is not an embedded id.
enum PlaybackTrackOrigin { embedded, automatic, disabled, externalFile, externalData }

class PlaybackAudioTrack {
  const PlaybackAudioTrack(
    this.id,
    this.title,
    this.language, {
    this.origin = PlaybackTrackOrigin.embedded,
    this.isDefault,
    this.codec,
    this.channels,
  });

  const PlaybackAudioTrack.automatic() : this('auto', null, null, origin: PlaybackTrackOrigin.automatic);
  final String id;
  final String? title;
  final String? language;
  final PlaybackTrackOrigin origin;
  final bool? isDefault;
  final String? codec;
  final String? channels;

  bool get isAutomatic => origin == PlaybackTrackOrigin.automatic;

  bool get isDisabled => origin == PlaybackTrackOrigin.disabled;

  @override
  bool operator ==(Object other) => other is PlaybackAudioTrack && id == other.id && origin == other.origin;

  @override
  int get hashCode => Object.hash(id, origin);
}

class PlaybackSubtitleTrack {
  const PlaybackSubtitleTrack(
    this.id,
    this.title,
    this.language, {
    this.origin = PlaybackTrackOrigin.embedded,
    this.isDefault,
  });

  const PlaybackSubtitleTrack.automatic() : this('auto', null, null, origin: PlaybackTrackOrigin.automatic);

  const PlaybackSubtitleTrack.disabled() : this('no', null, null, origin: PlaybackTrackOrigin.disabled);

  const PlaybackSubtitleTrack.externalFile(String path, {String? title})
    : this(path, title, null, origin: PlaybackTrackOrigin.externalFile);
  final String id;
  final String? title;
  final String? language;
  final PlaybackTrackOrigin origin;
  final bool? isDefault;

  bool get isAutomatic => origin == PlaybackTrackOrigin.automatic;

  bool get isDisabled => origin == PlaybackTrackOrigin.disabled;

  @override
  bool operator ==(Object other) => other is PlaybackSubtitleTrack && id == other.id && origin == other.origin;

  @override
  int get hashCode => Object.hash(id, origin);
}

class PlaybackTracks {
  const PlaybackTracks({this.audio = const [], this.subtitle = const []});

  final List<PlaybackAudioTrack> audio;
  final List<PlaybackSubtitleTrack> subtitle;
}

class PlaybackSelectedTracks {
  const PlaybackSelectedTracks({
    this.audio = const PlaybackAudioTrack.automatic(),
    this.subtitle = const PlaybackSubtitleTrack.automatic(),
  });

  final PlaybackAudioTrack audio;
  final PlaybackSubtitleTrack subtitle;
}
