/// A media location and the request headers required to open it.
class PlaybackTarget {
  final String url;
  final Map<String, String> httpHeaders;
  final PlaybackTargetResource? resource;

  const PlaybackTarget({required this.url, this.httpHeaders = const {}, this.resource});

  /// Owned by the playback session; release after the backend stops using it.
  Future<void> release() async => resource?.close();
}

/// A target's optional runtime resource. Implementations must close idempotently.
abstract interface class PlaybackTargetResource {
  Future<void> close();
}
