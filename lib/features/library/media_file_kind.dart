enum MediaFileKind { directory, video, other }

class MediaFileKindResolver {
  const MediaFileKindResolver._();

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
