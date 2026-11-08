// 【目录筛选】定义标题类型标签和年份范围条件。
// 由目录页面保存选择，供应用查询契约和 SQL 实现使用。

enum LibraryTitleSort { latestAdded, releaseYear, rating, title }

class LibraryTitleFilter {
  const LibraryTitleFilter({this.genres = const {}, this.decade});

  final Set<String> genres;
  final int? decade;

  int get count => (genres.isEmpty ? 0 : 1) + (decade == null ? 0 : 1);
}
