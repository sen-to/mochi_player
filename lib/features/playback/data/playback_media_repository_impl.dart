// 【数据访问】将播放文件读取与字段级进度更新适配到共享数据库。
// 不保存完整旧文件快照，避免覆盖其他业务更新。

import 'package:mochi_player/core/data/database/app_database.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/features/playback/application/playback_media_repository.dart';

class PlaybackMediaRepositoryImpl implements PlaybackMediaRepository {
  PlaybackMediaRepositoryImpl({required AppDatabase database}) : _database = database;

  final AppDatabase _database;
  @override
  Future<MediaFile?> readMediaFile({required String sourceId, required String path}) =>
      _database.getMediaFile(sourceId, path);

  @override
  Future<void> updateProgress(MediaFile file, int position, {int? duration}) async {
    final row = await _database.getMediaFile(file.sourceId, file.path);
    if (row == null) return;
    await _database.updateProgress(row, position, duration: duration);
  }
}
