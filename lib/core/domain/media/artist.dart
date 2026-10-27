// 【共享模型】描述演员身份、角色与图片信息。
// 供元数据转换、数据库及界面共同使用。

/// 演员 Domain Model
class Artist {
  final String? tmdbId;
  final String name;
  final String? character;
  final String? profileUrl;

  const Artist({this.tmdbId, required this.name, this.character, this.profileUrl});
}
