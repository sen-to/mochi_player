import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/platform/window_service.dart';
import 'package:mochi_player/core/domain/storage/smb_source_location.dart';
import 'package:mochi_player/features/library/application/storage_sources_service.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/home/application/trending_media_provider.dart';
import 'package:mochi_player/features/library/application/file_browser_provider.dart';
import 'package:mochi_player/features/library/application/media_library_provider.dart';
import 'package:mochi_player/features/settings/application/app_settings_provider.dart';
import 'package:mochi_player/features/settings/application/theme_provider.dart';
import 'package:mochi_player/features/settings/domain/app_settings.dart';
import 'package:mochi_player/features/settings/presentation/widgets/language_preference_control.dart';
import 'package:mochi_player/features/settings/presentation/widgets/settings_section.dart';
import 'package:mochi_player/features/settings/presentation/widgets/settings_switch_item.dart';
import 'package:mochi_player/features/settings/presentation/widgets/settings_text_field.dart';
import 'package:mochi_player/features/settings/presentation/widgets/theme_preference_controls.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

enum _SettingsTab { general, mediaSource, metadata, playback }

enum _StorageSourceAddOption { local, webDav, smb }

class _SettingsPageState extends State<SettingsPage> {
  StorageSourcesService get _sourceController => context.read<StorageSourcesService>();
  final _tmdbApiKeyController = TextEditingController();
  final _tmdbApiBaseUrlController = TextEditingController();
  final _tmdbProxyUrlController = TextEditingController();
  final _playbackCacheSizeMbController = TextEditingController();
  final _playbackReadaheadSecondsController = TextEditingController();
  final _subtitleLanguagePriorityController = TextEditingController();

  bool _controllersInitialized = false;
  bool _isSyncingControllers = false;
  bool _showTmdbApiKey = false;
  bool _tmdbProxyEnabled = AppSettings.defaultTmdbProxyEnabled;
  bool _enableHardwareAcceleration = AppSettings.defaultEnableHardwareAcceleration;
  double _subtitleFontSize = AppSettings.defaultSubtitleFontSize;
  var _selectedTab = _SettingsTab.general;
  Timer? _saveDebounce;
  bool _autoSaveInFlight = false;
  bool _autoSavePending = false;
  bool _runtimeApplyPending = false;
  List<StorageSource> _storageSources = const [];
  bool _isLoadingStorageSources = true;

  List<TextEditingController> get _settingsControllers => [
    _tmdbApiKeyController,
    _tmdbApiBaseUrlController,
    _tmdbProxyUrlController,
    _playbackCacheSizeMbController,
    _playbackReadaheadSecondsController,
    _subtitleLanguagePriorityController,
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_loadStorageSources());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controllersInitialized) return;

    final settings = context.read<AppSettingsProvider>();
    _syncServices(settings);
    for (final controller in _settingsControllers) {
      controller.addListener(_scheduleAutoSave);
    }
    _controllersInitialized = true;
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    for (final controller in _settingsControllers) {
      controller.removeListener(_scheduleAutoSave);
    }
    _tmdbApiKeyController.dispose();
    _tmdbApiBaseUrlController.dispose();
    _tmdbProxyUrlController.dispose();
    _playbackCacheSizeMbController.dispose();
    _playbackReadaheadSecondsController.dispose();
    _subtitleLanguagePriorityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          SizedBox(
            height: AppHeader.height,
            child: AppHeader(title: context.l10n.settings),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: AppTabs<_SettingsTab>(
                  value: _selectedTab,
                  onChanged: (tab) => setState(() => _selectedTab = tab),
                  tabs: [
                    AppTab(value: _SettingsTab.general, label: context.l10n.general, icon: Icons.tune_rounded),
                    AppTab(
                      value: _SettingsTab.mediaSource,
                      label: context.l10n.mediaSources,
                      icon: Icons.storage_outlined,
                    ),
                    AppTab(value: _SettingsTab.metadata, label: context.l10n.metadata, icon: Icons.sell_outlined),
                    AppTab(
                      value: _SettingsTab.playback,
                      label: context.l10n.playback,
                      icon: Icons.play_circle_outline_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              key: PageStorageKey<String>('settings-scroll:${_selectedTab.name}'),
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.xxl, AppSpacing.page, AppSpacing.page),
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1040),
                    child: _buildSelectedTab(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTab(BuildContext context) {
    return switch (_selectedTab) {
      _SettingsTab.general => _buildGeneralSettings(context),
      _SettingsTab.mediaSource => _buildWebDavSettings(context),
      _SettingsTab.metadata => _buildTmdbSettings(context),
      _SettingsTab.playback => _buildPlaybackSettings(context),
    };
  }

  Widget _buildGeneralSettings(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return SettingsSection(
          title: context.l10n.general,
          subtitle: context.l10n.appearanceLanguageDescription,
          groups: [
            AppFormGroup(
              title: context.l10n.interfaceTheme,
              children: [
                ThemeModePicker(
                  value: themeProvider.themeMode,
                  accentColor: themeProvider.accentColor.color,
                  onChanged: themeProvider.setTheme,
                ),
              ],
            ),
            AppFormGroup(
              title: context.l10n.preferences,
              children: [
                AppFormItem(
                  label: context.l10n.accentColor,
                  subtitle: context.l10n.accentDescription,
                  labelWidth: null,
                  control: AccentColorPicker(value: themeProvider.accentColor, onChanged: themeProvider.setAccentColor),
                  expandControl: false,
                ),
                AppFormItem(
                  label: context.l10n.applicationLanguage,
                  labelWidth: null,
                  control: const LanguagePreferenceControl(),
                  expandControl: false,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildWebDavSettings(BuildContext context) {
    return SettingsSection(
      title: context.l10n.mediaSources,
      subtitle: context.l10n.mediaSourcesDescription,
      groups: [
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
                control: _SettingsActionButton(
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
                control: _SettingsActionButton(
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
                _StorageSourceAddOption.webDav => _showStorageSourceEditor(),
                _StorageSourceAddOption.smb => _showSmbSourceEditor(),
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
              StorageSourceType.local => _showLocalSourceEditor(source: source),
              StorageSourceType.webDav => _showStorageSourceEditor(source: source),
              StorageSourceType.smb => _showSmbSourceEditor(source: source),
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

  Future<String?> _pickLocalDirectory({String? initialDirectory}) async {
    try {
      return await context.read<WindowService>().pickDirectory(initialDirectory: initialDirectory);
    } catch (error) {
      debugPrint('打开目录选择器失败: $error');
      if (mounted) AppMessage.error(context, context.l10n.directorySelectionFailed);
      return null;
    }
  }

  Future<void> _pickAndAddLocalSource() async {
    final directoryPath = await _pickLocalDirectory();
    if (directoryPath == null || directoryPath.isEmpty || !mounted) return;
    await _showLocalSourceEditor(initialDirectory: directoryPath);
  }

  Future<void> _showLocalSourceEditor({StorageSource? source, String? initialDirectory}) async {
    var directoryPath = initialDirectory ?? source?.endpoint ?? '';
    final nameController = TextEditingController(
      text: source?.name ?? (directoryPath.isEmpty ? '' : path.basename(directoryPath)),
    );
    var isEnabled = source?.enabled ?? true;
    var isTestingConnection = false;
    String? formError;
    String? connectionTestResult;
    bool? connectionTestSucceeded;
    StateSetter? updateModal;

    void showFormError(String message) {
      updateModal?.call(() => formError = message);
    }

    Future<void> chooseDirectory() async {
      final selected = await _pickLocalDirectory(initialDirectory: directoryPath.isEmpty ? null : directoryPath);
      if (selected == null || selected.isEmpty) return;
      updateModal?.call(() {
        directoryPath = selected;
        if (nameController.text.trim().isEmpty) {
          nameController.text = path.basename(selected);
        }
        formError = null;
        connectionTestResult = null;
        connectionTestSucceeded = null;
      });
    }

    Future<void> testConnection() async {
      if (directoryPath.isEmpty) {
        showFormError(context.l10n.selectLocalFolder);
        return;
      }
      updateModal?.call(() {
        formError = null;
        isTestingConnection = true;
        connectionTestResult = null;
        connectionTestSucceeded = null;
      });
      try {
        await _sourceController.testConnection(
          StorageSource(
            id: source?.id ?? 'connection-test',
            name: nameController.text.trim().isEmpty ? path.basename(directoryPath) : nameController.text.trim(),
            type: StorageSourceType.local,
            endpoint: directoryPath,
          ),
          null,
        );
        updateModal?.call(() {
          connectionTestSucceeded = true;
          connectionTestResult = context.l10n.connectionSucceeded;
        });
      } catch (error, stackTrace) {
        debugPrint('测试本地目录失败: $error\n$stackTrace');
        updateModal?.call(() {
          connectionTestSucceeded = false;
          connectionTestResult = context.l10n.directoryAccessFailed;
        });
      } finally {
        updateModal?.call(() => isTestingConnection = false);
      }
    }

    try {
      final saved = await AppModal.show(
        context: context,
        title: source == null ? context.l10n.addLocalFolder : context.l10n.editLocalFolder,
        icon: Icons.folder_outlined,
        confirmLabel: source == null ? context.l10n.add : context.l10n.save,
        content: StatefulBuilder(
          builder: (context, setModalState) {
            updateModal = setModalState;
            return AppFormGroup(
              children: [
                _buildStorageSourceFormItem(
                  label: context.l10n.name,
                  controller: nameController,
                  placeholder: context.l10n.libraryNameExample,
                ),
                AppFormItem(
                  label: context.l10n.localFolder,
                  subtitleBelowControl: true,
                  subtitle: directoryPath.isEmpty ? context.l10n.selectFolderDescription : directoryPath,
                  labelWidth: 104,
                  control: Align(
                    alignment: Alignment.centerRight,
                    child: AppButton(
                      onPressed: chooseDirectory,
                      label: directoryPath.isEmpty ? context.l10n.chooseFolder : context.l10n.changeFolder,
                      icon: Icons.folder_open_outlined,
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.compact,
                    ),
                  ),
                ),
                if (source != null)
                  SettingsSwitchItem(
                    label: context.l10n.enableSource,
                    subtitle: context.l10n.disableSourceDescription,
                    value: isEnabled,
                    onChanged: (value) => setModalState(() => isEnabled = value),
                  ),
                AppFormItem(
                  label: context.l10n.connectionTest,
                  subtitle: connectionTestResult,
                  subtitleColor: connectionTestSucceeded == true
                      ? AppColors.success(context)
                      : AppColors.danger(context),
                  labelWidth: null,
                  expandControl: false,
                  control: AppButton(
                    onPressed: isTestingConnection ? null : testConnection,
                    label: isTestingConnection ? context.l10n.testing : context.l10n.testFolder,
                    icon: Icons.wifi_tethering_outlined,
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.compact,
                    busy: isTestingConnection,
                  ),
                ),
                if (formError != null)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      formError!,
                      style: TextStyle(color: AppColors.danger(context), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            );
          },
        ),
        onConfirm: () async {
          if (directoryPath.isEmpty) {
            showFormError(context.l10n.selectLocalFolder);
            return false;
          }
          if (!await Directory(directoryPath).exists()) {
            if (!mounted) return false;
            showFormError(context.l10n.folderUnavailable);
            return false;
          }
          try {
            await _sourceController.save(
              StorageSource(
                id: source?.id ?? const Uuid().v4(),
                name: nameController.text.trim().isEmpty ? path.basename(directoryPath) : nameController.text.trim(),
                type: StorageSourceType.local,
                endpoint: directoryPath,
                rootPath: '/',
                enabled: isEnabled,
              ),
            );
            return true;
          } catch (error, stackTrace) {
            debugPrint('保存本地目录失败: $error\n$stackTrace');
            if (!mounted) return false;
            showFormError(context.l10n.localFolderSaveFailed);
            return false;
          }
        },
      );
      if (saved == true) {
        var clearedActiveSource = false;
        if (source != null && mounted) {
          final fileBrowser = context.read<FileBrowserProvider>();
          if (fileBrowser.activeSource?.id == source.id) {
            fileBrowser.clearStorageSource();
            clearedActiveSource = true;
          }
        }
        await _loadStorageSources();
        if (mounted) {
          AppMessage.success(
            context,
            source == null
                ? context.l10n.localFolderAdded
                : clearedActiveSource
                ? context.l10n.sourceSavedReopen
                : context.l10n.sourceSaved,
          );
        }
      }
    } finally {
      nameController.dispose();
    }
  }

  Future<void> _showSmbSourceEditor({StorageSource? source}) async {
    final endpoint = Uri.tryParse(source?.endpoint ?? '');
    final nameController = TextEditingController(text: source?.name ?? '');
    final hostController = TextEditingController(text: endpoint?.host ?? '');
    final shareController = TextEditingController(
      text: endpoint?.pathSegments.where((segment) => segment.isNotEmpty).firstOrNull ?? '',
    );
    final rootPathController = TextEditingController(text: source?.rootPath ?? '/');
    final existingCredentials = source == null ? null : await _sourceController.readCredentials(source.id);
    final usernameController = TextEditingController(text: existingCredentials?.username ?? '');
    final passwordController = TextEditingController(text: existingCredentials?.password ?? '');
    if (!mounted) {
      nameController.dispose();
      hostController.dispose();
      shareController.dispose();
      rootPathController.dispose();
      usernameController.dispose();
      passwordController.dispose();
      return;
    }

    var showPassword = false;
    var isEnabled = source?.enabled ?? true;
    var isTestingConnection = false;
    String? formError;
    String? connectionTestResult;
    bool? connectionTestSucceeded;
    StateSetter? updateModal;

    void showFormError(String message) {
      updateModal?.call(() => formError = message);
    }

    StorageSource? draftSource() {
      final host = hostController.text.trim();
      final share = shareController.text.trim().replaceAll(RegExp(r'^/+|/+$'), '');
      if (host.isEmpty) {
        showFormError(context.l10n.smbHostRequired);
        return null;
      }
      if (share.isEmpty || share.contains('/')) {
        showFormError(context.l10n.smbShareRequired);
        return null;
      }
      final rootPath = SmbSourceLocation.normalizeRootPath(rootPathController.text);
      return StorageSource(
        id: source?.id ?? 'connection-test',
        name: nameController.text.trim().isEmpty ? '$host / $share' : nameController.text.trim(),
        type: StorageSourceType.smb,
        endpoint: Uri(scheme: 'smb', host: host, path: '/$share').toString(),
        rootPath: rootPath,
        enabled: isEnabled,
      );
    }

    Future<void> testConnection() async {
      final draft = draftSource();
      if (draft == null) return;
      updateModal?.call(() {
        formError = null;
        isTestingConnection = true;
        connectionTestResult = null;
        connectionTestSucceeded = null;
      });
      try {
        await _sourceController.testConnection(
          draft,
          StorageCredentials(username: usernameController.text.trim(), password: passwordController.text),
        );
        updateModal?.call(() {
          connectionTestSucceeded = true;
          connectionTestResult = context.l10n.connectionSucceeded;
        });
      } catch (error, stackTrace) {
        debugPrint('测试 SMB 连接失败: $error\n$stackTrace');
        updateModal?.call(() {
          connectionTestSucceeded = false;
          connectionTestResult = context.l10n.connectionFailedDetail(_describeSmbConnectionError(error));
        });
      } finally {
        updateModal?.call(() => isTestingConnection = false);
      }
    }

    try {
      final saved = await AppModal.show(
        context: context,
        title: source == null ? context.l10n.addSmbSource : context.l10n.editSmbSource,
        icon: Icons.lan_outlined,
        confirmLabel: source == null ? context.l10n.add : context.l10n.save,
        content: StatefulBuilder(
          builder: (context, setModalState) {
            updateModal = setModalState;
            return AppFormGroup(
              children: [
                _buildStorageSourceFormItem(
                  label: context.l10n.name,
                  controller: nameController,
                  placeholder: context.l10n.nasNameExample,
                ),
                _buildStorageSourceFormItem(
                  label: context.l10n.host,
                  controller: hostController,
                  placeholder: context.l10n.smbHostExample,
                ),
                _buildStorageSourceFormItem(
                  label: context.l10n.shareName,
                  controller: shareController,
                  placeholder: context.l10n.shareNameExample,
                ),
                _buildStorageSourceFormItem(
                  label: context.l10n.sharePath,
                  controller: rootPathController,
                  placeholder: context.l10n.sharePathExample,
                ),
                if (source != null)
                  SettingsSwitchItem(
                    label: context.l10n.enableSource,
                    subtitle: context.l10n.disableSourceDescription,
                    value: isEnabled,
                    onChanged: (value) => setModalState(() => isEnabled = value),
                  ),
                _buildStorageSourceFormItem(label: context.l10n.username, controller: usernameController),
                _buildStorageSourceFormItem(
                  label: context.l10n.password,
                  controller: passwordController,
                  obscureText: !showPassword,
                  suffix: AppButton.icon(
                    onPressed: () => setModalState(() => showPassword = !showPassword),
                    icon: showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    tooltip: showPassword ? context.l10n.hidePassword : context.l10n.showPassword,
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.compact,
                  ),
                ),
                AppFormItem(
                  label: context.l10n.connectionTest,
                  subtitle: connectionTestResult,
                  subtitleColor: connectionTestSucceeded == true
                      ? AppColors.success(context)
                      : AppColors.danger(context),
                  labelWidth: null,
                  expandControl: false,
                  control: AppButton(
                    onPressed: isTestingConnection ? null : testConnection,
                    label: isTestingConnection ? context.l10n.testing : context.l10n.testConnection,
                    icon: Icons.wifi_tethering_outlined,
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.compact,
                    busy: isTestingConnection,
                  ),
                ),
                if (formError != null)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      formError!,
                      style: TextStyle(color: AppColors.danger(context), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            );
          },
        ),
        onConfirm: () async {
          final draft = draftSource();
          if (draft == null) return false;
          try {
            await _sourceController.save(
              StorageSource(
                id: source?.id ?? const Uuid().v4(),
                name: draft.name,
                type: StorageSourceType.smb,
                endpoint: draft.endpoint,
                rootPath: draft.rootPath,
                enabled: draft.enabled,
              ),
              credentials: StorageCredentials(
                username: usernameController.text.trim(),
                password: passwordController.text,
              ),
            );
            return true;
          } catch (error, stackTrace) {
            debugPrint('保存 SMB 媒体源失败: $error\n$stackTrace');
            if (!mounted) return false;
            showFormError(context.l10n.smbSourceSaveFailed);
            return false;
          }
        },
      );
      if (saved == true) {
        var clearedActiveSource = false;
        if (source != null && mounted) {
          final fileBrowser = context.read<FileBrowserProvider>();
          if (fileBrowser.activeSource?.id == source.id) {
            fileBrowser.clearStorageSource();
            clearedActiveSource = true;
          }
        }
        await _loadStorageSources();
        if (mounted) {
          AppMessage.success(
            context,
            source == null
                ? context.l10n.smbSourceAdded
                : clearedActiveSource
                ? context.l10n.sourceSavedReopen
                : context.l10n.sourceSaved,
          );
        }
      }
    } finally {
      nameController.dispose();
      hostController.dispose();
      shareController.dispose();
      rootPathController.dispose();
      usernameController.dispose();
      passwordController.dispose();
    }
  }

  Future<void> _showStorageSourceEditor({StorageSource? source}) async {
    final nameController = TextEditingController(text: source?.name ?? '');
    final existingEndpoint = Uri.tryParse(source?.endpoint ?? '');
    final hostController = TextEditingController(text: existingEndpoint?.host ?? '');
    final pathController = TextEditingController(
      text: source == null ? '' : _combineWebDavPaths(existingEndpoint?.path, source.rootPath),
    );
    final portController = TextEditingController(
      text: existingEndpoint != null && existingEndpoint.host.isNotEmpty ? '${existingEndpoint.port}' : '',
    );
    final existingCredentials = source == null ? null : await _sourceController.readCredentials(source.id);
    final usernameController = TextEditingController(text: existingCredentials?.username ?? '');
    final passwordController = TextEditingController(text: existingCredentials?.password ?? '');
    if (!mounted) {
      nameController.dispose();
      hostController.dispose();
      pathController.dispose();
      portController.dispose();
      usernameController.dispose();
      passwordController.dispose();
      return;
    }
    var showPassword = false;
    // A local WebDAV endpoint (for example port 5244) commonly serves HTTP.
    // Existing sources retain their saved scheme; newly added sources start
    // with HTTPS disabled and can opt in when a server has TLS configured.
    var useHttps = existingEndpoint?.scheme == 'https';
    var isEnabled = source?.enabled ?? true;
    String? formError;
    String? connectionTestResult;
    bool? connectionTestSucceeded;
    var isTestingConnection = false;
    StateSetter? updateModal;

    void showFormError(String message) {
      updateModal?.call(() => formError = message);
    }

    Future<void> testConnection() async {
      final host = hostController.text.trim();
      if (host.isEmpty) {
        showFormError(context.l10n.webdavHostRequired);
        return;
      }
      final portText = portController.text.trim();
      if (portText.isEmpty) {
        showFormError(context.l10n.webdavPortRequired);
        return;
      }
      final port = int.tryParse(portText);
      if (port == null || port < 1 || port > 65535) {
        showFormError(context.l10n.portRangeError);
        return;
      }

      updateModal?.call(() {
        formError = null;
        isTestingConnection = true;
        connectionTestResult = null;
        connectionTestSucceeded = null;
      });
      try {
        final endpoint = Uri(
          scheme: useHttps ? 'https' : 'http',
          host: host,
          port: port,
          path: _normalizeWebDavPath(pathController.text),
        ).toString();
        await _sourceController.testConnection(
          StorageSource(
            id: source?.id ?? 'connection-test',
            name: nameController.text.trim().isEmpty ? host : nameController.text.trim(),
            type: StorageSourceType.webDav,
            endpoint: endpoint,
          ),
          StorageCredentials(username: usernameController.text.trim(), password: passwordController.text),
        );
        updateModal?.call(() {
          connectionTestSucceeded = true;
          connectionTestResult = context.l10n.connectionSucceeded;
        });
      } catch (error, stackTrace) {
        debugPrint('测试 WebDAV 连接失败: $error\n$stackTrace');
        updateModal?.call(() {
          connectionTestSucceeded = false;
          connectionTestResult = context.l10n.connectionFailedDetail(_describeConnectionError(error));
        });
      } finally {
        updateModal?.call(() => isTestingConnection = false);
      }
    }

    try {
      final saved = await AppModal.show(
        context: context,
        title: source == null ? context.l10n.addWebdavSource : context.l10n.editMediaSource,
        icon: Icons.dns_outlined,
        confirmLabel: source == null ? context.l10n.add : context.l10n.save,
        content: StatefulBuilder(
          builder: (context, setModalState) {
            updateModal = setModalState;
            return AppFormGroup(
              children: [
                _buildStorageSourceFormItem(
                  label: context.l10n.name,
                  controller: nameController,
                  placeholder: context.l10n.nasNameExample,
                ),
                _buildStorageSourceFormItem(
                  label: context.l10n.host,
                  controller: hostController,
                  placeholder: context.l10n.webdavHostExample,
                ),
                _buildStorageSourceFormItem(
                  label: context.l10n.webdavPath,
                  controller: pathController,
                  placeholder: '/dav',
                ),
                _buildStorageSourceFormItem(
                  label: context.l10n.port,
                  controller: portController,
                  placeholder: context.l10n.webdavPortHint,
                  keyboardType: TextInputType.number,
                ),
                AppFormItem(
                  label: 'HTTPS',
                  labelWidth: 104,
                  height: 48,
                  control: Align(
                    alignment: Alignment.centerRight,
                    child: AppSwitch(value: useHttps, onChanged: (value) => setModalState(() => useHttps = value)),
                  ),
                ),
                if (source != null)
                  SettingsSwitchItem(
                    label: context.l10n.enableSource,
                    subtitle: context.l10n.disableSourceDescription,
                    value: isEnabled,
                    onChanged: (value) => setModalState(() => isEnabled = value),
                  ),
                _buildStorageSourceFormItem(
                  label: context.l10n.username,
                  controller: usernameController,
                  placeholder: context.l10n.webdavUsernameHint,
                ),
                _buildStorageSourceFormItem(
                  label: context.l10n.password,
                  controller: passwordController,
                  placeholder: context.l10n.webdavPasswordHint,
                  obscureText: !showPassword,
                  suffix: AppButton.icon(
                    onPressed: () => setModalState(() => showPassword = !showPassword),
                    icon: showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    tooltip: showPassword ? context.l10n.hidePassword : context.l10n.showPassword,
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.compact,
                  ),
                ),
                AppFormItem(
                  label: context.l10n.connectionTest,
                  subtitle: connectionTestResult,
                  subtitleColor: connectionTestSucceeded == true
                      ? AppColors.success(context)
                      : AppColors.danger(context),
                  labelWidth: null,
                  expandControl: false,
                  control: AppButton(
                    onPressed: isTestingConnection ? null : testConnection,
                    label: isTestingConnection ? context.l10n.testing : context.l10n.testConnection,
                    icon: Icons.wifi_tethering_outlined,
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.compact,
                    busy: isTestingConnection,
                  ),
                ),
                if (formError != null)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      formError!,
                      style: TextStyle(color: AppColors.danger(context), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            );
          },
        ),
        onConfirm: () async {
          final host = hostController.text.trim();
          if (host.isEmpty) {
            showFormError(context.l10n.webdavHostRequired);
            return false;
          }
          final portText = portController.text.trim();
          if (portText.isEmpty) {
            showFormError(context.l10n.webdavPortRequired);
            return false;
          }
          final port = int.tryParse(portText);
          if (port == null || port < 1 || port > 65535) {
            showFormError(context.l10n.portRangeError);
            return false;
          }
          final path = _normalizeWebDavPath(pathController.text);
          final endpoint = Uri(scheme: useHttps ? 'https' : 'http', host: host, port: port, path: path).toString();
          final uri = Uri.tryParse(endpoint);
          if (uri == null || uri.host.isEmpty) {
            showFormError(context.l10n.webdavHostInvalid);
            return false;
          }
          try {
            await _sourceController.save(
              StorageSource(
                id: source?.id ?? const Uuid().v4(),
                name: nameController.text.trim().isEmpty ? host : nameController.text.trim(),
                type: StorageSourceType.webDav,
                endpoint: endpoint,
                rootPath: '/',
                enabled: isEnabled,
              ),
              credentials: StorageCredentials(
                username: usernameController.text.trim(),
                password: passwordController.text,
              ),
            );
            return true;
          } catch (error, stackTrace) {
            debugPrint('保存媒体源失败: $error\n$stackTrace');
            if (!mounted) return false;
            showFormError(context.l10n.sourceSaveFailed);
            return false;
          }
        },
      );
      if (saved == true) {
        var clearedActiveSource = false;
        if (source != null && mounted) {
          final fileBrowser = context.read<FileBrowserProvider>();
          if (fileBrowser.activeSource?.id == source.id) {
            fileBrowser.clearStorageSource();
            clearedActiveSource = true;
          }
        }
        await _loadStorageSources();
        if (mounted) {
          AppMessage.success(
            context,
            source == null
                ? context.l10n.sourceAdded
                : clearedActiveSource
                ? context.l10n.sourceSavedReopen
                : context.l10n.sourceSaved,
          );
        }
      }
    } finally {
      nameController.dispose();
      hostController.dispose();
      pathController.dispose();
      portController.dispose();
      usernameController.dispose();
      passwordController.dispose();
    }
  }

  String _normalizeWebDavPath(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '/') return '/';
    final prefixed = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return prefixed.replaceFirst(RegExp(r'/+$'), '');
  }

  String _describeConnectionError(Object error) {
    final message = error.toString();
    if (message.contains('401')) return context.l10n.authenticationFailed;
    if (message.contains('403')) return context.l10n.permissionDenied;
    if (message.contains('404')) return context.l10n.webdavPathMissing;
    if (message.contains('HandshakeException') || message.contains('WRONG_VERSION_NUMBER')) {
      return context.l10n.httpsMismatch;
    }
    if (message.contains('SocketException')) return context.l10n.serverUnavailable;
    return context.l10n.webdavConnectionAdvice;
  }

  String _describeSmbConnectionError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('auth') || message.contains('logon') || message.contains('access denied')) {
      return context.l10n.authenticationFailed;
    }
    if (message.contains('not found') || message.contains('no such')) {
      return context.l10n.smbShareMissing;
    }
    if (message.contains('connection') || message.contains('socket') || message.contains('timeout')) {
      return context.l10n.smbServerUnavailable;
    }
    return context.l10n.smbConnectionAdvice;
  }

  String _combineWebDavPaths(String? endpointPath, String? rootPath) {
    final endpoint = _normalizeWebDavPath(endpointPath ?? '/');
    final root = _normalizeWebDavPath(rootPath ?? '/');
    if (endpoint == '/') return root;
    if (root == '/') return endpoint;
    return '$endpoint$root';
  }

  Widget _buildStorageSourceFormItem({
    required String label,
    required TextEditingController controller,
    String? placeholder,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return AppFormItem(
      label: label,
      labelWidth: 104,
      height: 48,
      control: AppInput(
        controller: controller,
        placeholder: placeholder,
        keyboardType: keyboardType,
        obscureText: obscureText,
        suffix: suffix,
      ),
    );
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

  Widget _buildTmdbSettings(BuildContext context) {
    return Selector<AppSettingsProvider, bool>(
      selector: (context, provider) => provider.isSaving,
      builder: (context, isBusy, child) {
        return SettingsSection(
          title: context.l10n.metadata,
          subtitle: context.l10n.metadataDescription,
          groups: [
            AppFormGroup(
              title: context.l10n.tmdbConfiguration,
              children: [
                SettingsTextField(
                  controller: _tmdbApiBaseUrlController,
                  keyboardType: TextInputType.url,
                  label: context.l10n.apiUrl,
                  onFocusLost: _commitNetworkSettings,
                ),
                SettingsTextField(
                  controller: _tmdbApiKeyController,
                  obscureText: !_showTmdbApiKey,
                  label: context.l10n.apiKey,
                  onFocusLost: _commitNetworkSettings,
                  inputSuffix: _VisibilityToggle(
                    visible: _showTmdbApiKey,
                    onPressed: () {
                      setState(() {
                        _showTmdbApiKey = !_showTmdbApiKey;
                      });
                    },
                  ),
                ),
                SettingsSwitchItem(
                  label: context.l10n.tmdbUseProxy,
                  subtitle: context.l10n.tmdbProxyDescription,
                  value: _tmdbProxyEnabled,
                  onChanged: (value) {
                    setState(() {
                      _tmdbProxyEnabled = value;
                    });
                    _scheduleAutoSave(applyRuntime: true, immediate: true);
                  },
                ),
                if (_tmdbProxyEnabled)
                  SettingsTextField(
                    controller: _tmdbProxyUrlController,
                    keyboardType: TextInputType.url,
                    label: context.l10n.httpProxy,
                    onFocusLost: _commitNetworkSettings,
                  ),
                AppFormItem(
                  label: context.l10n.connectionStatus,
                  subtitle: context.l10n.tmdbTestDescription,
                  labelWidth: null,
                  expandControl: false,
                  control: _SettingsActionButton(
                    onPressed: isBusy ? null : _testTmdbConnection,
                    label: context.l10n.testConnection,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaybackSettings(BuildContext context) {
    return SettingsSection(
      title: context.l10n.playback,
      subtitle: context.l10n.playbackDescription,
      groups: [
        AppFormGroup(
          title: context.l10n.cacheSettings,
          children: [
            SettingsTextField(
              controller: _playbackCacheSizeMbController,
              keyboardType: TextInputType.number,
              label: context.l10n.cacheSize,
              suffixText: 'MB',
              maxWidth: 120,
            ),
            SettingsTextField(
              controller: _playbackReadaheadSecondsController,
              keyboardType: TextInputType.number,
              label: context.l10n.readahead,
              suffixText: context.l10n.secondsUnit,
              maxWidth: 120,
            ),
          ],
        ),
        AppFormGroup(
          title: context.l10n.playbackSettings,
          children: [
            SettingsSwitchItem(
              label: context.l10n.hardwareDecoding,
              value: _enableHardwareAcceleration,
              onChanged: (value) {
                setState(() {
                  _enableHardwareAcceleration = value;
                });
                _scheduleAutoSave();
              },
            ),
          ],
        ),
        AppFormGroup(
          title: context.l10n.subtitleSettings,
          children: [
            SettingsTextField(controller: _subtitleLanguagePriorityController, label: context.l10n.subtitleLanguage),
            AppFormItem(
              label: context.l10n.subtitleSize,
              control: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 160,
                  child: AppInputNumber(
                    value: _subtitleFontSize.round(),
                    min: 18,
                    max: 40,
                    onChanged: (value) {
                      setState(() {
                        _subtitleFontSize = value.toDouble();
                      });
                      _scheduleAutoSave();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _scheduleAutoSave({bool applyRuntime = false, bool immediate = false}) {
    if (!_controllersInitialized || _isSyncingControllers) return;
    if (applyRuntime) _runtimeApplyPending = true;

    _saveDebounce?.cancel();
    _saveDebounce = Timer(immediate ? Duration.zero : const Duration(milliseconds: 450), () {
      unawaited(_autoSaveSettings());
    });
  }

  void _commitNetworkSettings() {
    _scheduleAutoSave(applyRuntime: true, immediate: true);
  }

  Future<void> _autoSaveSettings() async {
    if (!mounted) return;
    if (_autoSaveInFlight) {
      _autoSavePending = true;
      return;
    }

    _autoSaveInFlight = true;
    final shouldApplyRuntime = _runtimeApplyPending;
    _runtimeApplyPending = false;
    try {
      final settingsProvider = context.read<AppSettingsProvider>();
      final previousRuntimeSettings = settingsProvider.appliedRuntimeSettings ?? settingsProvider.settings;
      await _persistSettings(applyRuntime: shouldApplyRuntime, syncServices: false);
      if (mounted && settingsProvider.error == null) {
        final currentSettings = settingsProvider.settings;
        if (shouldApplyRuntime) {
          unawaited(_refreshAfterRuntimeSettingsApplied(previousRuntimeSettings, currentSettings));
        }
      }
    } finally {
      _autoSaveInFlight = false;
      if (_autoSavePending && mounted) {
        _autoSavePending = false;
        _scheduleAutoSave(immediate: _runtimeApplyPending);
      }
    }
  }

  Future<void> _testTmdbConnection() async {
    final didSave = await _persistSettings(applyRuntime: true);
    if (!didSave || !mounted) return;

    final settingsProvider = context.read<AppSettingsProvider>();
    final isConnected = await settingsProvider.testTmdbConnection();
    if (!mounted) return;

    if (isConnected) {
      AppMessage.success(context, context.l10n.tmdbConnected);
    } else {
      final error = settingsProvider.error;
      AppMessage.error(context, error == null ? context.l10n.tmdbConnectionFailed : context.l10n.failure(error));
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

  Future<bool> _persistSettings({bool applyRuntime = false, bool syncServices = true}) async {
    final settingsProvider = context.read<AppSettingsProvider>();

    await settingsProvider.saveSettings(
      tmdbApiKey: _tmdbApiKeyController.text,
      tmdbApiBaseUrl: _tmdbApiBaseUrlController.text,
      tmdbProxyUrl: _tmdbProxyUrlController.text,
      tmdbProxyEnabled: _tmdbProxyEnabled,
      playbackCacheSizeMb: _parseIntField(_playbackCacheSizeMbController, AppSettings.defaultPlaybackCacheSizeMb),
      playbackReadaheadSeconds: _parseIntField(
        _playbackReadaheadSecondsController,
        AppSettings.defaultPlaybackReadaheadSeconds,
      ),
      enableHardwareAcceleration: _enableHardwareAcceleration,
      subtitleLanguagePriority: _subtitleLanguagePriorityController.text,
      subtitleFontSize: _subtitleFontSize,
      applyRuntime: applyRuntime,
    );
    if (!mounted) return false;

    final error = settingsProvider.error;
    if (error != null) {
      AppMessage.error(context, context.l10n.failure(error));
      return false;
    }

    if (syncServices) _syncServices(settingsProvider);
    if (mounted && syncServices) setState(() {});
    return true;
  }

  Future<void> _refreshAfterRuntimeSettingsApplied(AppSettings previousSettings, AppSettings currentSettings) async {
    final tmdbChanged =
        previousSettings.tmdbApiKey != currentSettings.tmdbApiKey ||
        previousSettings.tmdbApiBaseUrl != currentSettings.tmdbApiBaseUrl ||
        previousSettings.tmdbProxyUrl != currentSettings.tmdbProxyUrl ||
        previousSettings.tmdbProxyEnabled != currentSettings.tmdbProxyEnabled;

    if (!mounted) return;

    if (tmdbChanged && mounted && (previousSettings.hasTmdbApiKey || currentSettings.hasTmdbApiKey)) {
      await context.read<TrendingMediaProvider>().fetch();
    }
  }

  void _syncServices(AppSettingsProvider settingsProvider) {
    _isSyncingControllers = true;
    try {
      _setControllerText(_tmdbApiKeyController, settingsProvider.tmdbApiKey);
      _setControllerText(_tmdbApiBaseUrlController, settingsProvider.tmdbApiBaseUrl);
      _setControllerText(_tmdbProxyUrlController, settingsProvider.tmdbProxyUrl);
      _tmdbProxyEnabled = settingsProvider.tmdbProxyEnabled;
      _setControllerText(_playbackCacheSizeMbController, settingsProvider.playbackCacheSizeMb.toString());
      _setControllerText(_playbackReadaheadSecondsController, settingsProvider.playbackReadaheadSeconds.toString());
      _enableHardwareAcceleration = settingsProvider.enableHardwareAcceleration;
      _setControllerText(_subtitleLanguagePriorityController, settingsProvider.subtitleLanguagePriority);
      _subtitleFontSize = settingsProvider.subtitleFontSize;
    } finally {
      _isSyncingControllers = false;
    }
  }

  void _setControllerText(TextEditingController controller, String text) {
    if (controller.text == text) return;

    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  int _parseIntField(TextEditingController controller, int fallback) {
    return int.tryParse(controller.text.trim()) ?? fallback;
  }
}

class _VisibilityToggle extends StatelessWidget {
  final bool visible;
  final VoidCallback onPressed;

  const _VisibilityToggle({required this.visible, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: visible ? context.l10n.hide : context.l10n.show,
      child: AppClickableArea(
        width: 22,
        height: 22,
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.small),
        hoverColor: AppColors.hoverSurface(context),
        child: Center(
          child: Icon(
            visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 16,
            color: AppColors.textSecondary(context),
          ),
        ),
      ),
    );
  }
}

class _SettingsActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool destructive;
  final bool busy;

  const _SettingsActionButton({
    required this.onPressed,
    required this.label,
    this.icon,
    this.destructive = false,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      onPressed: onPressed,
      icon: icon,
      label: label,
      destructive: destructive,
      busy: busy,
      variant: AppButtonVariant.secondary,
      size: AppButtonSize.compact,
    );
  }
}
