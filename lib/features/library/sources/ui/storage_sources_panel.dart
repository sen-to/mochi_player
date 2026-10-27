// 【来源配置界面】展示来源列表并连接新增、编辑、删除、扫描和清库操作。
// 业务进入来源服务或媒体库 Provider，不直接访问协议或数据库。

import 'package:flutter/material.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/application/media_library_provider.dart';
import 'package:mochi_player/features/library/sources/application/storage_sources_service.dart';
import 'package:mochi_player/features/library/sources/ui/local_source_dialog.dart';
import 'package:mochi_player/features/library/sources/ui/smb_source_dialog.dart';
import 'package:mochi_player/features/library/sources/ui/source_form_fields.dart';
import 'package:mochi_player/features/library/sources/ui/webdav_source_dialog.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:provider/provider.dart';

class StorageSourcesPanel extends StatefulWidget {
  const StorageSourcesPanel({super.key});
  @override
  State<StorageSourcesPanel> createState() => _StorageSourcesPanelState();
}

enum _StorageSourceAddOption { local, webDav, smb }

class _StorageSourcesPanelState extends State<StorageSourcesPanel> {
  StorageSourcesService get _sourceController => context.read<StorageSourcesService>();
  List<StorageSource> _storageSources = const [];
  bool _isLoadingStorageSources = true;

  @override
  void initState() {
    super.initState();
    _loadStorageSources();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFormGroup(
          title: context.l10n.mediaSources,
          trailing: _buildAddStorageSourceMenu(),
          children: [
            if (_isLoadingStorageSources)
              const SizedBox(height: 88, child: Center(child: CircularProgressIndicator.adaptive()))
            else if (_storageSources.isEmpty)
              AppFormItem(
                label: context.l10n.noMediaSources,
                subtitle: context.l10n.addSourceDescription,
                labelWidth: null,
                expandControl: false,
                control: SizedBox.shrink(),
              )
            else
              for (final source in _storageSources) _buildStorageSourceItem(context, source),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Selector<MediaLibraryProvider, bool>(
          selector: (context, provider) => provider.isLoading,
          builder: (context, isBusy, child) => AppFormGroup(
            title: context.l10n.library,
            children: [
              AppFormItem(
                label: context.l10n.scanSources,
                subtitle: context.l10n.scanDescription,
                labelWidth: null,
                expandControl: false,
                control: AppButton(
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.compact,
                  onPressed: isBusy ? null : _confirmScanMediaSources,
                  icon: Icons.manage_search_outlined,
                  label: isBusy ? context.l10n.scanning : context.l10n.startScan,
                  busy: isBusy,
                ),
              ),
              AppFormItem(
                label: context.l10n.clearLibrary,
                subtitle: context.l10n.clearLibraryDescription,
                labelWidth: null,
                expandControl: false,
                control: AppButton(
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.compact,
                  onPressed: isBusy ? null : _confirmClearLibrary,
                  icon: Icons.delete_sweep_outlined,
                  label: context.l10n.clear,
                  destructive: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddStorageSourceMenu() {
    return Builder(
      builder: (context) => AppDropdown<_StorageSourceAddOption>(
        trigger: Container(
          height: 34,
          padding: const EdgeInsets.only(left: AppSpacing.sm, right: AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.controlSurface(context),
            borderRadius: BorderRadius.circular(AppRadii.control),
            border: Border.all(color: AppColors.separator(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 16, color: AppColors.textPrimary(context)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                context.l10n.add,
                style: TextStyle(color: AppColors.textPrimary(context), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(AppIcons.chevronDown, size: 14, color: AppColors.textSecondary(context)),
            ],
          ),
        ),
        tooltip: context.l10n.addMediaSource,
        menuWidth: 152,
        menuAlignment: AppDropdownMenuAlignment.end,
        onSelected: _isLoadingStorageSources
            ? null
            : (option) => switch (option) {
                _StorageSourceAddOption.local => _pickAndAddLocalSource(),
                _StorageSourceAddOption.webDav => showWebDavSourceDialog(context, onSaved: _loadStorageSources),
                _StorageSourceAddOption.smb => showSmbSourceDialog(context, onSaved: _loadStorageSources),
              },
        options: [
          AppDropdownOption(
            value: _StorageSourceAddOption.local,
            label: context.l10n.localFolder,
            icon: Icons.folder_outlined,
          ),
          AppDropdownOption(value: _StorageSourceAddOption.webDav, label: 'WebDAV', icon: Icons.language_rounded),
          AppDropdownOption(value: _StorageSourceAddOption.smb, label: 'SMB', icon: Icons.lan_outlined),
        ],
      ),
    );
  }

  Widget _buildStorageSourceItem(BuildContext context, StorageSource source) {
    return AppFormItem(
      label: source.name,
      subtitle: source.enabled ? source.endpoint : context.l10n.disabledEndpoint(source.endpoint),
      icon: switch (source.type) {
        StorageSourceType.local => Icons.folder_outlined,
        StorageSourceType.webDav => Icons.dns_outlined,
        StorageSourceType.smb => Icons.lan_outlined,
      },
      labelWidth: null,
      expandControl: false,
      control: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton.icon(
            onPressed: () => switch (source.type) {
              StorageSourceType.local => showLocalSourceDialog(context, source: source, onSaved: _loadStorageSources),
              StorageSourceType.webDav => showWebDavSourceDialog(context, source: source, onSaved: _loadStorageSources),
              StorageSourceType.smb => showSmbSourceDialog(context, source: source, onSaved: _loadStorageSources),
            },
            icon: Icons.edit_outlined,
            tooltip: context.l10n.editMediaSource,
            size: AppButtonSize.compact,
          ),
          const SizedBox(width: AppSpacing.xs),
          AppButton.icon(
            onPressed: () => _confirmDeleteStorageSource(source),
            icon: Icons.delete_outline_rounded,
            tooltip: context.l10n.deleteMediaSource,
            size: AppButtonSize.compact,
          ),
        ],
      ),
    );
  }

  Future<void> _loadStorageSources() async {
    try {
      final sources = await _sourceController.getAll();
      if (!mounted) return;
      setState(() {
        _storageSources = sources;
        _isLoadingStorageSources = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingStorageSources = false);
      AppMessage.error(context, context.l10n.sourcesLoadFailed);
    }
  }

  Future<void> _pickAndAddLocalSource() async {
    final directoryPath = await pickLocalDirectory(context);
    if (directoryPath == null || directoryPath.isEmpty || !mounted) return;
    await showLocalSourceDialog(context, initialDirectory: directoryPath, onSaved: _loadStorageSources);
  }

  Future<void> _confirmDeleteStorageSource(StorageSource source) async {
    final confirmed = await AppModal.confirm(
      context: context,
      title: context.l10n.deleteSourceConfirm,
      message: context.l10n.deleteSourceDescription(source.name),
      confirmLabel: context.l10n.delete,
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (confirmed != true) return;
    try {
      final deletedFileCount = await _sourceController.deleteWithMedia(source.id);
      if (deletedFileCount == null) {
        if (!mounted) return;
        AppMessage.error(context, context.l10n.sourceMissing);
        return;
      }
      if (!mounted) return;
      await _loadStorageSources();
      if (mounted) {
        AppMessage.success(context, context.l10n.sourceDeleted(deletedFileCount));
      }
    } catch (error, stackTrace) {
      debugPrint('删除媒体源失败: $error\n$stackTrace');
      if (mounted) AppMessage.error(context, context.l10n.sourceDeleteFailed);
    }
  }

  Future<void> _confirmScanMediaSources() async {
    final confirmed = await AppModal.confirm(
      context: context,
      title: context.l10n.scanConfirm,
      message: context.l10n.scanConfirmDescription,
      confirmLabel: context.l10n.startScan,
      icon: Icons.manage_search_rounded,
    );

    if (confirmed != true || !mounted) return;

    final mediaLibraryProvider = context.read<MediaLibraryProvider>();
    final summary = await mediaLibraryProvider.scanMediaSources();
    if (!mounted) return;

    final error = mediaLibraryProvider.error;
    if (summary == null) {
      AppMessage.error(context, error == null ? context.l10n.scanFailed : context.l10n.failure(error));
      return;
    }
    final message = context.l10n.scanSummary(
      summary.discoveredFileCount,
      summary.newFileCount,
      summary.removedFileCount,
    );
    final metadataMessage = switch ((summary.metadataMatchedCount, summary.metadataFailedCount)) {
      (final int matched, final int failed) => context.l10n.metadataSummary(matched, failed),
      _ => context.l10n.metadataSkipped,
    };
    if (error != null) {
      AppMessage.error(context, context.l10n.scanResultWithError(message, context.l10n.failure(error)));
    } else if (summary.failedSourceCount > 0) {
      AppMessage.error(context, context.l10n.scanPartialFailure(message, summary.failedSourceCount, metadataMessage));
    } else if (summary.metadataFailedCount case final failed? when failed > 0) {
      AppMessage.warning(context, context.l10n.scanResultWithMetadata(message, metadataMessage));
    } else {
      AppMessage.success(context, context.l10n.scanResultWithMetadata(message, metadataMessage));
    }
  }

  Future<void> _confirmClearLibrary() async {
    final confirmed = await AppModal.confirm(
      context: context,
      title: context.l10n.clearLibraryConfirm,
      message: context.l10n.clearLibraryConfirmDescription,
      confirmLabel: context.l10n.clear,
      icon: Icons.delete_sweep_rounded,
      destructive: true,
    );

    if (confirmed != true || !mounted) return;

    final mediaLibraryProvider = context.read<MediaLibraryProvider>();

    await mediaLibraryProvider.clearLibrary();
    if (!mounted) return;

    AppMessage.success(context, context.l10n.libraryCleared);
  }
}
