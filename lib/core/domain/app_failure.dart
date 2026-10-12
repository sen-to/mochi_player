/// User-facing failures carry semantic codes; diagnostic exceptions stay in logs.
enum AppFailure {
  settingsLoad,
  settingsSave,
  sourceRequired,
  filesLoad,
  scanSourceRequired,
  scanFailed,
  scrapeFailed,
  contentLoad,
  playbackLink,
  playbackOpen,
  playerLaunch,
}

enum LibraryActivityKind { scanning, scraping }

class LibraryActivity {
  const LibraryActivity({
    required this.kind,
    required this.completed,
    required this.total,
    this.success = 0,
    this.failed = 0,
    this.title = '',
  });

  final LibraryActivityKind kind;
  final int completed;
  final int total;
  final int success;
  final int failed;
  final String title;
}
