// 【媒体库规则】根据扩展名区分目录、视频和其他条目。
// 文件浏览与扫描复用，不负责元数据匹配。

enum MediaFileKind { directory, video, other }

class MediaFileClassifier {
  const MediaFileClassifier._();

  static const videoExtensions = {'mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm', 'ts', 'm2ts', 'mpg', 'mpeg', 'm4v'};

  static MediaFileKind resolve(String fileName, {bool isDirectory = false}) {
    if (isDirectory) return MediaFileKind.directory;
    final extension = extensionOf(fileName);
    if (videoExtensions.contains(extension)) return MediaFileKind.video;
    return MediaFileKind.other;
  }

  static String extensionOf(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == fileName.length - 1) return '';
    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  static bool isVideoExtension(String extension) =>
      videoExtensions.contains(extension.toLowerCase().replaceFirst('.', ''));
}
