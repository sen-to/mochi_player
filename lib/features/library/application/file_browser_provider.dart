import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mochi_player/core/domain/app_failure.dart';
import 'package:mochi_player/core/domain/media/media_file.dart';
import 'package:mochi_player/core/domain/media/media_file_kind.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_provider_registry.dart';
import 'package:mochi_player/features/library/domain/file_browser_entry.dart';

enum FileBrowserViewMode { grid, list }

enum FileSortField { name, size, modifiedAt }

/// 文件浏览器 Provider
///
/// Owns directory navigation, filtering and sorting for the file browser.
class FileBrowserProvider extends ChangeNotifier {
  final StorageProviderRegistry _storageProviderRegistry;
  StorageConnection? _storageConnection;
  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  FileBrowserProvider({StorageProviderRegistry? storageProviderRegistry})
    : _storageProviderRegistry = storageProviderRegistry ?? StorageProviderRegistry.defaults();

  String get sourceId => _storageConnection?.source.id ?? '';

  StorageSource? get activeSource => _storageConnection?.source;

  bool get hasSelectedStorageSource => _storageConnection != null;

  // === 状态变量 ===
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

  // === Getters ===
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

  // 加载指定路径的文件
  Future<void> fetchFiles(String path) async {
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

  /// Selects a configured storage source and starts its browser at the root.
  Future<void> openStorageSource(StorageSource source, StorageCredentials? credentials) async {
    final connection = await _storageProviderRegistry.connect(source, credentials);
    final previousConnection = _storageConnection;
    _storageConnection = connection;
    if (previousConnection != null) unawaited(previousConnection.close());
    _items = [];
    _currentPath = '/';
    _searchQuery = '';
    _error = null;
    _hasLoaded = false;
    await fetchFiles('/');
  }

  /// Returns the browser to its source-selection state.
  void clearStorageSource() {
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
            kind: MediaFileKindResolver.resolve(entry.name, isDirectory: entry.isDirectory),
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

  /// Adapts a playable browser entry to the playback API's media model.
  /// Browser state itself never stores this temporary object.
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
      container: MediaFileKindResolver.extensionOf(entry.name),
      addedAt: entry.modifiedAt ?? DateTime.now(),
    );
  }

  // === 核心功能 3: 进入文件夹 ===
  void enterFolder(FileBrowserEntry folder) {
    if (!folder.isDirectory) return;
    fetchFiles(folder.path);
  }

  // === 核心功能 4: 返回上一级目录 ===
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

  // === 辅助功能: 刷新当前目录 ===
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

  @override
  void dispose() {
    _requestGeneration++;
    final connection = _storageConnection;
    if (connection != null) unawaited(connection.close());
    super.dispose();
  }
}
