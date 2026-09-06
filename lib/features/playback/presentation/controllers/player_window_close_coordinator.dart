/// Coordinates a graceful player-window shutdown without coupling [PlayerPage]
/// to the desktop multi-window implementation.
class PlayerWindowCloseCoordinator {
  Future<void> Function()? _flushProgress;
  Future<void>? _flushInFlight;

  void registerProgressFlusher(Future<void> Function() flusher) {
    _flushProgress = flusher;
    _flushInFlight = null;
  }

  void unregisterProgressFlusher() {
    _flushProgress = null;
    _flushInFlight = null;
  }

  Future<void> flushProgress() async {
    final flusher = _flushProgress;
    if (flusher == null) return;
    final flush = _flushInFlight ??= flusher();
    try {
      await flush;
    } finally {
      if (identical(_flushInFlight, flush)) _flushInFlight = null;
    }
  }
}
