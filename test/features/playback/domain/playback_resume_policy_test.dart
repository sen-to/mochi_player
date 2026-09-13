import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/features/playback/domain/playback_resume_policy.dart';

MediaFile _file({int position = 0, int duration = 0}) => MediaFile(
  id: 1,
  path: '/media/movie.mkv',
  fileName: 'movie.mkv',
  parsedTitle: 'Movie',
  position: position,
  duration: duration,
  addedAt: DateTime(2026),
);

void main() {
  test('does not resume an untouched, restored, or completed item', () {
    expect(PlaybackResumePolicy.positionFor(_file(), hasRestoredPosition: false), isNull);
    expect(
      PlaybackResumePolicy.positionFor(_file(position: 30000, duration: 100000), hasRestoredPosition: true),
      isNull,
    );
    expect(
      PlaybackResumePolicy.positionFor(_file(position: 95000, duration: 100000), hasRestoredPosition: false),
      isNull,
    );
  });

  test('resumes with a five-second backoff without becoming negative', () {
    expect(
      PlaybackResumePolicy.positionFor(_file(position: 30000, duration: 100000), hasRestoredPosition: false),
      const Duration(seconds: 25),
    );
    expect(
      PlaybackResumePolicy.positionFor(_file(position: 3000, duration: 100000), hasRestoredPosition: false),
      isNull,
    );
  });
}
