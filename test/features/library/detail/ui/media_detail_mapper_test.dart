// 【展示映射测试】验证详情 VO 的字段回退、类型信息及集合快照。
// 转换只读取业务模型，VO 不再封装业务模型到展示字段的映射逻辑。

import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/features/library/detail/ui/media_detail_mapper.dart';

void main() {
  test('movie projection resolves image fallbacks and isolates mutable source lists', () {
    final cast = [const Artist(name: '演员')];
    final movie = Movie(tmdbId: '1', title: '电影', cast: cast);
    final details = MediaDetailMapper.toVO(movie);
    cast.add(const Artist(name: '后来加入'));
    expect(details.isMovie, true);
    expect(details.isTVShow, false);
    expect(details.posterUrl, isEmpty);
    expect(details.backdropUrl, isEmpty);
    expect(details.cast, hasLength(1));
    expect(() => details.cast.add(const Artist(name: '修改')), throwsUnsupportedError);
  });
  test('show projection distinguishes provider season total from indexed seasons', () {
    const show = TVShow(
      tmdbId: '2',
      title: '剧集',
      numberOfSeasons: 4,
      seasons: [Season(tvShowTmdbId: '2', seasonNumber: 1, title: '第一季')],
    );
    final details = MediaDetailMapper.toVO(show);
    expect(details.isTVShow, true);
    expect(details.totalSeasonCount, 4);
    expect(details.seasons, hasLength(1));
  });
}
