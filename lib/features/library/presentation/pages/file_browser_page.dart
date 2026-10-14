import 'package:flutter/material.dart';
import 'package:mochi_player/core/domain/app_failure.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_source_service.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/application/file_browser_provider.dart';
import 'package:mochi_player/features/library/domain/file_browser_entry.dart';
import 'package:mochi_player/features/library/presentation/widgets/file_browser_grid_tile.dart';
import 'package:mochi_player/features/library/presentation/widgets/file_browser_list.dart';
import 'package:mochi_player/features/library/presentation/widgets/file_browser_toolbar.dart';
import 'package:mochi_player/features/playback/presentation/playback_launcher.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:provider/provider.dart';

class FileBrowserPage extends StatefulWidget {
  const FileBrowserPage({super.key});

  @override
  State<FileBrowserPage> createState() => _FileBrowserPageState();
}

class _FileBrowserPageState extends State<FileBrowserPage> {
  final _storageSourceService = StorageSourceService();
  var _sources = const <StorageSource>[];
  var _isLoadingSources = true;
  AppFailure? _sourceError;
  bool _showSourceList = true;
  String? _openingSourceId;
  bool _didScheduleExternalSelection = false;

  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FileBrowserProvider>();
    final shouldShowSourceList = !provider.hasSelectedStorageSource;
    if (_showSourceList != shouldShowSourceList) {
      _scheduleSourceListVisibility(shouldShowSourceList);
    }
    final showSourceList = shouldShowSourceList || _showSourceList;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: context.l10n.fileBrowser,
            trailing: showSourceList
                ? null
                : SizedBox(
                    width: 300,
                    child: AppSearchInput(
                      placeholder: context.l10n.searchDirectory,
                      onChanged: provider.setSearchQuery,
                    ),
                  ),
          ),
          Expanded(
            child: showSourceList
                ? _StorageSourceListBody(
                    sources: _sources,
                    isLoading: _isLoadingSources,
                    error: _sourceError,
                    openingSourceId: _openingSourceId,
                    onSourceSelected: _openSource,
                    onRefresh: _loadSources,
                  )
                : Selector<FileBrowserProvider, _FileBrowserState>(
                    selector: (context, fileProvider) => _FileBrowserState(
                      sourceName: fileProvider.activeSource?.name,
                      sourceType: fileProvider.activeSource?.type,
                      items: fileProvider.visibleItems,
                      totalItemCount: fileProvider.items.length,
                      isLoading: fileProvider.isLoading,
                      hasLoaded: fileProvider.hasLoaded,
                      error: fileProvider.error,
                      currentPath: fileProvider.currentPath,
                      canGoBack: fileProvider.canGoBack,
                      viewMode: fileProvider.viewMode,
                      sortField: fileProvider.sortField,
                      sortAscending: fileProvider.sortAscending,
                      hasSearchQuery: fileProvider.searchQuery.trim().isNotEmpty,
                    ),
                    builder: (context, state, child) => _FileBrowserBody(
                      state: state,
                      provider: context.read<FileBrowserProvider>(),
                      onItemTap: (item) => _onItemTap(context, item, provider),
                      onSourceSelected: _showSources,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _scheduleSourceListVisibility(bool shouldShowSourceList) {
    if (_didScheduleExternalSelection) return;
    _didScheduleExternalSelection = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _showSourceList == shouldShowSourceList) {
        _didScheduleExternalSelection = false;
        return;
      }
      setState(() {
        _showSourceList = shouldShowSourceList;
        _didScheduleExternalSelection = false;
      });
    });
  }

  Future<void> _loadSources() async {
    if (mounted) {
      setState(() {
        _isLoadingSources = true;
        _sourceError = null;
      });
    }
    try {
      final sources = (await _storageSourceService.getAll()).where((source) => source.enabled).toList(growable: false);
      if (!mounted) return;
      setState(() {
        _sources = sources;
        _isLoadingSources = false;
      });
    } catch (error, stackTrace) {
      debugPrint('加载媒体源失败: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _isLoadingSources = false;
        _sourceError = AppFailure.contentLoad;
      });
    }
  }

  Future<void> _openSource(StorageSource source) async {
    if (!source.enabled || _openingSourceId != null) return;
    setState(() => _openingSourceId = source.id);
    try {
      final credentials = await _storageSourceService.readCredentials(source.id);
      if (!mounted) return;
      await context.read<FileBrowserProvider>().openStorageSource(source, credentials);
      if (!mounted) return;
      setState(() => _showSourceList = false);
    } catch (error, stackTrace) {
      debugPrint(
        '打开媒体源失败: name=${source.name}, type=${source.type.name}, '
        'endpoint=${source.endpoint}, error=$error\n$stackTrace',
      );
      if (mounted) AppMessage.error(context, context.l10n.sourceConnectionFailed(source.name));
    } finally {
      if (mounted) setState(() => _openingSourceId = null);
    }
  }

  void _showSources() {
    context.read<FileBrowserProvider>().clearStorageSource();
    setState(() => _showSourceList = true);
    _loadSources();
  }

  void _onItemTap(BuildContext context, FileBrowserEntry item, FileBrowserProvider provider) {
    if (item.isDirectory) {
      provider.enterFolder(item);
      return;
    }
    if (!item.isPlayable) return;
    PlaybackLauncher.playFile(
      context,
      provider.createPlaybackFile(item),
      loadingMessage: context.l10n.fetchingPlaybackLink(item.name),
      failureMessage: context.l10n.playbackLinkFailed,
    );
  }
}

class _StorageSourceListBody extends StatelessWidget {
  const _StorageSourceListBody({
    required this.sources,
    required this.isLoading,
    required this.error,
    required this.openingSourceId,
    required this.onSourceSelected,
    required this.onRefresh,
  });

  final List<StorageSource> sources;
  final bool isLoading;
  final AppFailure? error;
  final String? openingSourceId;
  final ValueChanged<StorageSource> onSourceSelected;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.section, AppSpacing.xxl, AppSpacing.section, AppSpacing.xxl),
      child: Column(
        children: [
          FileBrowserToolbar(
            currentPath: '/',
            canGoBack: false,
            viewMode: FileBrowserViewMode.list,
            sortField: FileSortField.name,
            sortAscending: true,
            onBack: () {},
            onPathSelected: (_) {},
            onSortChanged: (_, _) {},
            onViewModeChanged: (_) {},
            onRefresh: onRefresh,
            showDirectoryControls: false,
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (error != null)
            Expanded(
              child: AppResult(
                status: AppResultStatus.error,
                title: context.l10n.sourcesLoadFailed,
                subtitle: error == null ? null : context.l10n.failure(error!),
              ),
            )
          else if (sources.isEmpty)
            Expanded(
              child: AppResult(
                status: AppResultStatus.empty,
                title: context.l10n.noMediaSources,
                subtitle: context.l10n.addSourcesInSettings,
                icon: Icon(Icons.dns_outlined),
              ),
            )
          else
            _StorageSourceTable(sources: sources, openingSourceId: openingSourceId, onSourceSelected: onSourceSelected),
        ],
      ),
    );
  }
}

class _StorageSourceTable extends StatelessWidget {
  const _StorageSourceTable({required this.sources, required this.openingSourceId, required this.onSourceSelected});

  final List<StorageSource> sources;
  final String? openingSourceId;
  final ValueChanged<StorageSource> onSourceSelected;

  @override
  Widget build(BuildContext context) {
    final separator = AppColors.separator(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: separator),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _StorageSourceTableHeader(),
          Divider(height: 1, thickness: 1, color: separator),
          for (var index = 0; index < sources.length; index++) ...[
            _StorageSourceTableRow(
              source: sources[index],
              isOpening: openingSourceId == sources[index].id,
              onTap: () => onSourceSelected(sources[index]),
            ),
            if (index != sources.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xl),
                child: Divider(height: 1, thickness: 1, color: separator),
              ),
          ],
        ],
      ),
    );
  }
}

class _StorageSourceTableHeader extends StatelessWidget {
  const _StorageSourceTableHeader();

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary(context));
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Row(
          children: [
            Expanded(flex: 6, child: Text(context.l10n.name, style: style)),
            Expanded(flex: 5, child: Text(context.l10n.location, style: style)),
            const SizedBox(width: 28),
          ],
        ),
      ),
    );
  }
}

class _StorageSourceTableRow extends StatelessWidget {
  const _StorageSourceTableRow({required this.source, required this.isOpening, required this.onTap});

  final StorageSource source;
  final bool isOpening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = !isOpening;
    final endpoint = Uri.tryParse(source.endpoint);
    final location = source.type == StorageSourceType.local
        ? source.endpoint
        : endpoint == null
        ? source.endpoint
        : endpoint.hasPort
        ? '${endpoint.host}:${endpoint.port}'
        : endpoint.host;
    final typeLabel = switch (source.type) {
      StorageSourceType.local => context.l10n.localFolder,
      StorageSourceType.webDav => 'WebDAV',
      StorageSourceType.smb => 'SMB',
    };
    final icon = switch (source.type) {
      StorageSourceType.local => Icons.folder_outlined,
      StorageSourceType.webDav => Icons.dns_outlined,
      StorageSourceType.smb => Icons.lan_outlined,
    };
    final muted = AppColors.textSecondary(context);

    return AppClickableArea(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.zero,
      hoverColor: AppColors.hoverSurface(context),
      child: SizedBox(
        height: 76,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primary(context).withAlpha(18),
                        borderRadius: BorderRadius.circular(AppRadii.control),
                      ),
                      child: Icon(icon, size: 19, color: AppColors.primary(context)),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            source.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textPrimary(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            typeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 5,
                child: Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textPrimary(context), fontSize: 13),
                ),
              ),
              SizedBox(
                width: 28,
                child: isOpening
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.chevron_right_rounded, size: 20, color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileBrowserBody extends StatelessWidget {
  final _FileBrowserState state;
  final FileBrowserProvider provider;
  final ValueChanged<FileBrowserEntry> onItemTap;
  final VoidCallback onSourceSelected;

  const _FileBrowserBody({
    required this.state,
    required this.provider,
    required this.onItemTap,
    required this.onSourceSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (state.sourceName == null) {
      return AppResult(status: AppResultStatus.info, title: context.l10n.selectMediaSource);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.section, AppSpacing.xxl, AppSpacing.section, AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FileBrowserToolbar(
            sourceName: state.sourceName!,
            sourceIcon: switch (state.sourceType) {
              StorageSourceType.local => Icons.folder_outlined,
              StorageSourceType.webDav => Icons.dns_outlined,
              StorageSourceType.smb => Icons.lan_outlined,
              null => Icons.dns_outlined,
            },
            currentPath: state.currentPath,
            canGoBack: true,
            viewMode: state.viewMode,
            sortField: state.sortField,
            sortAscending: state.sortAscending,
            onBack: () {
              if (state.canGoBack) {
                provider.navigateBack();
              } else {
                onSourceSelected();
              }
            },
            onPathSelected: provider.navigateToPath,
            onSortChanged: (field, ascending) => provider.setSort(field, ascending: ascending),
            onViewModeChanged: provider.setViewMode,
            onRefresh: provider.refresh,
            onRootSelected: onSourceSelected,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Expanded(child: _buildContent(context)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (state.isLoading || !state.hasLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.items.isEmpty) {
      if (state.hasSearchQuery) {
        return AppResult(
          status: AppResultStatus.empty,
          title: context.l10n.noMatchingFiles,
          subtitle: context.l10n.tryOtherKeywords,
          icon: Icon(Icons.search_off_rounded, size: 44, color: AppColors.textSecondary(context)),
        );
      }
      if (state.error != null) {
        return AppResult(
          status: AppResultStatus.error,
          title: context.l10n.filesLoadFailed,
          subtitle: context.l10n.failure(state.error!),
        );
      }
      return AppResult(
        status: AppResultStatus.empty,
        title: context.l10n.folderEmpty,
        icon: Icon(Icons.folder_open_outlined),
      );
    }
    if (state.viewMode == FileBrowserViewMode.grid) return _buildGrid();
    return _buildList();
  }

  Widget _buildGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GridView.builder(
            key: PageStorageKey<String>('file-browser-grid:${state.sourceName}:${state.currentPath}'),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 138,
              childAspectRatio: 0.95,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
            ),
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              return FileBrowserGridTile(
                item: item,
                onTap: item.isDirectory || item.isPlayable ? () => onItemTap(item) : null,
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildSummary(),
      ],
    );
  }

  Widget _buildList() {
    return FileBrowserListSection(
      items: state.items,
      totalItemCount: state.totalItemCount,
      isFiltered: state.hasSearchQuery,
      onItemTap: onItemTap,
      scrollStorageKey: PageStorageKey<String>('file-browser-list:${state.sourceName}:${state.currentPath}'),
    );
  }

  Widget _buildSummary() =>
      FileBrowserSummary(items: state.items, totalItemCount: state.totalItemCount, isFiltered: state.hasSearchQuery);
}

class _FileBrowserState {
  final String? sourceName;
  final StorageSourceType? sourceType;
  final List<FileBrowserEntry> items;
  final int totalItemCount;
  final bool isLoading;
  final bool hasLoaded;
  final AppFailure? error;
  final String currentPath;
  final bool canGoBack;
  final FileBrowserViewMode viewMode;
  final FileSortField sortField;
  final bool sortAscending;
  final bool hasSearchQuery;

  const _FileBrowserState({
    required this.sourceName,
    required this.sourceType,
    required this.items,
    required this.totalItemCount,
    required this.isLoading,
    required this.hasLoaded,
    required this.error,
    required this.currentPath,
    required this.canGoBack,
    required this.viewMode,
    required this.sortField,
    required this.sortAscending,
    required this.hasSearchQuery,
  });

  @override
  bool operator ==(Object other) {
    return other is _FileBrowserState &&
        other.sourceName == sourceName &&
        other.sourceType == sourceType &&
        _sameItems(other.items, items) &&
        other.totalItemCount == totalItemCount &&
        other.isLoading == isLoading &&
        other.hasLoaded == hasLoaded &&
        other.error == error &&
        other.currentPath == currentPath &&
        other.canGoBack == canGoBack &&
        other.viewMode == viewMode &&
        other.sortField == sortField &&
        other.sortAscending == sortAscending &&
        other.hasSearchQuery == hasSearchQuery;
  }

  @override
  int get hashCode => Object.hash(
    sourceName,
    sourceType,
    Object.hashAll(items),
    totalItemCount,
    isLoading,
    hasLoaded,
    error,
    currentPath,
    canGoBack,
    viewMode,
    sortField,
    sortAscending,
    hasSearchQuery,
  );

  static bool _sameItems(List<FileBrowserEntry> a, List<FileBrowserEntry> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (!identical(a[index], b[index])) return false;
    }
    return true;
  }
}
