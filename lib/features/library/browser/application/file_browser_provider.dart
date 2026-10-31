// 【界面状态与应用入口】维护当前来源、目录、过滤和排序，并协调浏览连接。
// 协议细节交给存储适配器；来源失效、切换和关闭时释放连接。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mochi_player/core/domain/app_failure.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/domain/storage/storage_adapter_registry.dart';
import 'package:mochi_player/features/library/browser/domain/file_browser_entry.dart';
import 'package:mochi_player/features/library/domain/media_file_kind.dart';

enum FileBrowserViewMode { grid, list }

enum FileSortField { name, size, modifiedAt }

/// 文件浏览器的界面状态与操作入口，负责目录导航、过滤及排序。
class FileBrowserProvider extends ChangeNotifier {
  final StorageAdapterRegistry _storageAdapterRegistry;
  final Future<StorageCredentials?> Function(String) _readCredentials;
  StorageConnection? _storageConnection;
  ({String id, int generation})? _openingSource;
  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  FileBrowserProvider({
    required StorageAdapterRegistry storageAdapterRegistry,
    required Future<StorageCredentials?> Function(String) readCredentials,
  }) : _storageAdapterRegistry = storageAdapterRegistry,
       _readCredentials = readCredentials;

  String get sourceId => _storageConnection?.source.id ?? '';

  StorageSource? get activeSource => _storageConnection?.source;

  bool get hasSelectedStorageSource => _storageConnection != null;

  // 当前目录及展示偏好；来源连接只由此 Provider 持有。
  List<FileBrowserEntry> _items = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String _currentPath = '/';
  AppFailure? _error;
  FileBrowserViewMode _viewMode = FileBrowserViewMode.list;
  FileSortField _sortField = FileSortField.name;
  bool _sortAscending = true;
  String _searchQuery = '';
  int _requestGeneration = 0;
  bool _shuttingDown = false;

  // 对外可读状态。
  List<FileBrowserEntry> get items => _items;

  bool get isLoading => _isLoading;

  bool get hasLoaded => _hasLoaded;

  String get currentPath => _currentPath;

  AppFailure? get error => _error;

  bool get canGoBack => _currentPath != '/';

  FileBrowserViewMode get viewMode => _viewMode;

  FileSortField get sortField => _sortField;

  bool get sortAscending => _sortAscending;

  String get searchQuery => _searchQuery;

  List<FileBrowserEntry> get visibleItems {
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final result = normalizedQuery.isEmpty
        ? List<FileBrowserEntry>.of(_items)
        : _items.where((item) => item.name.toLowerCase().contains(normalizedQuery)).toList();
    result.sort(_compareItems);
    return result;
  }

  void setSearchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    notifyListeners();
  }

  void setSort(FileSortField field, {required bool ascending}) {
    if (_sortField == field && _sortAscending == ascending) return;
    _sortField = field;
    _sortAscending = ascending;
    notifyListeners();
  }

  void setViewMode(FileBrowserViewMode value) {
    if (_viewMode == value) return;
    _viewMode = value;
    notifyListeners();
  }

  /// 加载来源相对路径；新请求或来源变化使旧结果失效，读取失败记入 error。
  Future<void> fetchFiles(String path) async {
    if (_shuttingDown) return;
    final requestGeneration = ++_requestGeneration;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!hasSelectedStorageSource) {
        _items = [];
        _error = AppFailure.sourceRequired;
        _hasLoaded = true;
        return;
      }

      final entries = await _readStorageDirectory(path);
      if (requestGeneration != _requestGeneration) return;

      _items = entries;

      _currentPath = path;
      _hasLoaded = true;
      _logger.i("✅ 加载成功，在 '$path' 发现 ${_items.length} 个文件");
    } catch (e) {
      if (requestGeneration != _requestGeneration) return;
      _logger.e("❌ 加载文件失败: $e");
      _items = [];
      _error = AppFailure.filesLoad;
      _hasLoaded = true;
    } finally {
      if (requestGeneration == _requestGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// 选择一个配置来源，并从其根目录开始浏览。
  Future<void> openStorageSource(StorageSource source) async {
    if (_shuttingDown) return;
    final generation = ++_requestGeneration;
    final opening = (id: source.id, generation: generation);
    _openingSource = opening;
    try {
      final credentials = await _readCredentials(source.id);
      if (_shuttingDown || generation != _requestGeneration) return;
      final connection = await _storageAdapterRegistry.connect(source, credentials);
      if (_shuttingDown || generation != _requestGeneration) {
        await connection.close();
        return;
      }
      _openingSource = null;
      final previousConnection = _storageConnection;
      _storageConnection = connection;
      if (previousConnection != null) unawaited(previousConnection.close());
      _items = [];
      _currentPath = '/';
      _searchQuery = '';
      _error = null;
      _hasLoaded = false;
      await fetchFiles('/');
    } finally {
      if (_openingSource == opening) _openingSource = null;
    }
  }

  /// 配置变化时使相关浏览失效，包括正在等待凭据或建立连接的请求。
  bool invalidateSource(String id) {
    if (_shuttingDown || (activeSource?.id != id && _openingSource?.id != id)) return false;
    clearStorageSource();
    return true;
  }

  /// 将浏览器恢复到来源选择状态。
  void clearStorageSource() {
    _openingSource = null;
    _requestGeneration++;
    final previousConnection = _storageConnection;
    _storageConnection = null;
    if (previousConnection != null) unawaited(previousConnection.close());
    _items = [];
    _currentPath = '/';
    _searchQuery = '';
    _error = null;
    _hasLoaded = false;
    _isLoading = false;
    notifyListeners();
  }

  Future<List<FileBrowserEntry>> _readStorageDirectory(String path) async {
    final entries = await _storageConnection!.readDirectory(path);
    return entries
        .where((entry) => entry.name.isNotEmpty && !entry.name.startsWith('.'))
        .map(
          (entry) => FileBrowserEntry(
            sourceId: sourceId,
            path: _entryPath(path, entry.name, entry.isDirectory),
            name: entry.name,
            kind: MediaFileClassifier.resolve(entry.name, isDirectory: entry.isDirectory),
            size: entry.size,
            modifiedAt: entry.modifiedAt,
          ),
        )
        .toList();
  }

  String _entryPath(String parentPath, String name, bool isDirectory) {
    var fullPath = parentPath.endsWith('/') ? '$parentPath$name' : '$parentPath/$name';
    if (isDirectory && !fullPath.endsWith('/')) fullPath += '/';
    return fullPath;
  }

  /// 将可播放条目转换为播放接口需要的媒体模型；浏览状态不保存这个临时对象。
  MediaFile createPlaybackFile(FileBrowserEntry entry) {
    if (!entry.isPlayable) {
      throw ArgumentError.value(entry.path, 'entry', 'File is not playable');
    }
    return MediaFile(
      id: -1,
      sourceId: entry.sourceId,
      path: entry.path,
      fileName: entry.name,
      parsedTitle: entry.name,
      size: entry.size,
      container: MediaFileClassifier.extensionOf(entry.name),
      addedAt: entry.modifiedAt ?? DateTime.now(),
    );
  }

  void enterFolder(FileBrowserEntry folder) {
    if (!folder.isDirectory) return;
    fetchFiles(folder.path);
  }

  void navigateBack() {
    if (!canGoBack) return;
    final normalized = _currentPath.replaceFirst(RegExp(r'/+$'), '');
    final parentSeparator = normalized.lastIndexOf('/');
    final parentPath = parentSeparator <= 0 ? '/' : normalized.substring(0, parentSeparator + 1);
    fetchFiles(parentPath);
  }

  void navigateToPath(String path) {
    if (path == _currentPath) return;
    fetchFiles(path);
  }

  Future<void> refresh() async {
    await fetchFiles(_currentPath);
  }

  int _compareItems(FileBrowserEntry a, FileBrowserEntry b) {
    final folderComparison = _compareFolders(a, b);
    if (folderComparison != 0) return folderComparison;

    final comparison = switch (_sortField) {
      FileSortField.name => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      FileSortField.size => a.size.compareTo(b.size),
      FileSortField.modifiedAt => _modifiedAt(a).compareTo(_modifiedAt(b)),
    };
    return _sortAscending ? comparison : -comparison;
  }

  int _compareFolders(FileBrowserEntry a, FileBrowserEntry b) {
    final aIsFolder = a.isDirectory;
    final bIsFolder = b.isDirectory;
    if (aIsFolder == bIsFolder) return 0;
    return aIsFolder ? -1 : 1;
  }

  DateTime _modifiedAt(FileBrowserEntry item) => item.modifiedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  void beginShutdown() {
    _shuttingDown = true;
    _requestGeneration++;
  }

  Future<void> shutdown() async {
    beginShutdown();
    final connection = _storageConnection;
    _storageConnection = null;
    await connection?.close();
  }

  @override
  void dispose() {
    beginShutdown();
    final connection = _storageConnection;
    _storageConnection = null;
    if (connection != null) unawaited(connection.close());
    super.dispose();
  }
}
