// 【凭据模型】封装媒体源连接所需的账号与密码。
// 不用于页面列表或日志展示。

/// 媒体源的认证信息。
class StorageCredentials {
  final String username;
  final String password;

  const StorageCredentials({this.username = '', this.password = ''});

  @override
  bool operator ==(Object other) {
    return other is StorageCredentials && other.username == username && other.password == password;
  }

  @override
  int get hashCode => Object.hash(username, password);
}
