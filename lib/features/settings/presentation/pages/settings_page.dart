import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/infrastructure/storage/local_directory_picker.dart';
import 'package:mochi_player/core/infrastructure/storage/smb_source_location.dart';
import 'package:mochi_player/core/infrastructure/storage/smb_storage_provider.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_provider_registry.dart';
import 'package:mochi_player/core/infrastructure/storage/storage_source_service.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/home/application/trending_media_provider.dart';
import 'package:mochi_player/features/library/application/file_browser_provider.dart';
import 'package:mochi_player/features/library/application/media_library_provider.dart';
import 'package:mochi_player/features/settings/application/app_settings_provider.dart';
import 'package:mochi_player/features/settings/application/theme_provider.dart';
import 'package:mochi_player/features/settings/domain/app_settings.dart';
import 'package:mochi_player/features/settings/presentation/widgets/settings_section.dart';
import 'package:mochi_player/features/settings/presentation/widgets/settings_switch_item.dart';
import 'package:mochi_player/features/settings/presentation/widgets/settings_text_field.dart';
import 'package:mochi_player/features/settings/presentation/widgets/theme_preference_controls.dart';
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
  final _storageSourceService = StorageSourceService();
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
    _syncControllers(settings);
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
          const SizedBox(
            height: AppHeader.height,
            child: AppHeader(title: '设置'),
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
                  tabs: const [
                    AppTab(value: _SettingsTab.general, label: '通用', icon: Icons.tune_rounded),
                    AppTab(value: _SettingsTab.mediaSource, label: '媒体源', icon: Icons.storage_outlined),
                    AppTab(value: _SettingsTab.metadata, label: '元数据', icon: Icons.sell_outlined),
                    AppTab(value: _SettingsTab.playback, label: '播放', icon: Icons.play_circle_outline_rounded),
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
          title: '通用',
          subtitle: '调整应用的外观与语言偏好',
          groups: [
            AppFormGroup(
              title: '界面主题',
              children: [
                ThemeModePicker(
                  value: themeProvider.themeMode,
                  accentColor: themeProvider.accentColor.color,
                  onChanged: themeProvider.setTheme,
                ),
              ],
            ),
            AppFormGroup(
              title: '偏好',
              children: [
                AppFormItem(
                  label: '强调色',
                  subtitle: '用于按钮、选中项和进度',
                  labelWidth: null,
                  control: AccentColorPicker(value: themeProvider.accentColor, onChanged: themeProvider.setAccentColor),
                  expandControl: false,
                ),
                AppFormItem(
                  label: '应用语言',
                  labelWidth: null,
                  control: SizedBox(
                    width: 120,
                    child: AppSelect<String>(
                      value: 'zh-CN',
                      options: [AppSelectOption(value: 'zh-CN', label: '简体中文')],
                      onChanged: (_) {},
                    ),
                  ),
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
      title: '媒体源',
      subtitle: '管理用于浏览、扫描与播放的本地和网络媒体源',
      groups: [
        AppFormGroup(
          title: '媒体源',
          trailing: _buildAddStorageSourceMenu(),
          children: [
            if (_isLoadingStorageSources)
              const SizedBox(height: 88, child: Center(child: CircularProgressIndicator.adaptive()))
            else if (_storageSources.isEmpty)
              const AppFormItem(
                label: '尚未添加媒体源',
                subtitle: '添加本地目录或 WebDAV 服务器后即可浏览媒体文件',
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
            title: '媒体库',
            children: [
              AppFormItem(
                label: '扫描媒体源',
                subtitle: '扫描全部启用的媒体源，新增文件并清理已删除的本地索引',
                labelWidth: null,
                expandControl: false,
                control: _SettingsActionButton(
                  onPressed: isBusy ? null : _confirmScanMediaSources,
                  icon: Icons.manage_search_outlined,
                  label: isBusy ? '扫描中' : '开始扫描',
                  busy: isBusy,
                ),
              ),
              AppFormItem(
                label: '清空媒体库',
                subtitle: '删除本地索引、元数据、播放进度和收藏，不会删除远程文件',
                labelWidth: null,
                expandControl: false,
                control: _SettingsActionButton(
                  onPressed: isBusy ? null : _confirmClearLibrary,
                  icon: Icons.delete_sweep_outlined,
                  label: '清空',
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
                '添加',
                style: TextStyle(color: AppColors.textPrimary(context), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(AppIcons.chevronDown, size: 14, color: AppColors.textSecondary(context)),
            ],
          ),
        ),
        tooltip: '添加媒体源',
        menuWidth: 152,
        menuAlignment: AppDropdownMenuAlignment.end,
        onSelected: _isLoadingStorageSources
            ? null
            : (option) => switch (option) {
                _StorageSourceAddOption.local => _pickAndAddLocalSource(),
                _StorageSourceAddOption.webDav => _showStorageSourceEditor(),
                _StorageSourceAddOption.smb => _showSmbSourceEditor(),
              },
        options: const [
          AppDropdownOption(value: _StorageSourceAddOption.local, label: '本地目录', icon: Icons.folder_outlined),
          AppDropdownOption(value: _StorageSourceAddOption.webDav, label: 'WebDAV', icon: Icons.language_rounded),
          AppDropdownOption(value: _StorageSourceAddOption.smb, label: 'SMB', icon: Icons.lan_outlined),
        ],
      ),
    );
  }

  Widget _buildStorageSourceItem(BuildContext context, StorageSource source) {
    return AppFormItem(
      label: source.name,
      subtitle: source.enabled ? source.endpoint : '已停用 · ${source.endpoint}',
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
            tooltip: '编辑媒体源',
            size: AppButtonSize.compact,
          ),
          const SizedBox(width: AppSpacing.xs),
          AppButton.icon(
            onPressed: () => _confirmDeleteStorageSource(source),
            icon: Icons.delete_outline_rounded,
            tooltip: '删除媒体源',
            size: AppButtonSize.compact,
          ),
        ],
      ),
    );
  }

  Future<void> _loadStorageSources() async {
    try {
      final sources = await _storageSourceService.getAll();
      if (!mounted) return;
      setState(() {
        _storageSources = sources;
        _isLoadingStorageSources = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingStorageSources = false);
      AppMessage.error('加载媒体源失败');
    }
  }

  Future<void> _pickAndAddLocalSource() async {
    final directoryPath = await const LocalDirectoryPicker().pickDirectory();
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
      final selected = await const LocalDirectoryPicker().pickDirectory(
        initialDirectory: directoryPath.isEmpty ? null : directoryPath,
      );
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
        showFormError('请选择本地目录');
        return;
      }
      updateModal?.call(() {
        formError = null;
        isTestingConnection = true;
        connectionTestResult = null;
        connectionTestSucceeded = null;
      });
      try {
        final connection = await StorageProviderRegistry.defaults().connect(
          StorageSource(
            id: source?.id ?? 'connection-test',
            name: nameController.text.trim().isEmpty ? path.basename(directoryPath) : nameController.text.trim(),
            type: StorageSourceType.local,
            endpoint: directoryPath,
          ),
          null,
        );
        final entries = await connection.readDirectory('/');
        updateModal?.call(() {
          connectionTestSucceeded = true;
          connectionTestResult = '目录可访问（${entries.length} 项）';
        });
      } catch (error, stackTrace) {
        debugPrint('测试本地目录失败: $error\n$stackTrace');
        updateModal?.call(() {
          connectionTestSucceeded = false;
          connectionTestResult = '无法访问该目录，请检查目录是否存在及授权是否允许';
        });
      } finally {
        updateModal?.call(() => isTestingConnection = false);
      }
    }

    try {
      final saved = await AppModal.show(
        context: context,
        title: source == null ? '添加本地目录' : '编辑本地目录',
        icon: Icons.folder_outlined,
        confirmLabel: source == null ? '添加' : '保存',
        content: StatefulBuilder(
          builder: (context, setModalState) {
            updateModal = setModalState;
            return AppFormGroup(
              children: [
                _buildStorageSourceFormItem(label: '名称', controller: nameController, placeholder: '例如：家庭媒体库'),
                AppFormItem(
                  label: '本地目录',
                  subtitle: directoryPath.isEmpty ? '请选择要用于浏览和扫描的目录' : directoryPath,
                  labelWidth: 104,
                  control: Align(
                    alignment: Alignment.centerRight,
                    child: AppButton(
                      onPressed: chooseDirectory,
                      label: directoryPath.isEmpty ? '选择目录' : '更改目录',
                      icon: Icons.folder_open_outlined,
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.compact,
                    ),
                  ),
                ),
                if (source != null)
                  AppFormItem(
                    label: '启用此媒体源',
                    subtitle: '停用后不会显示在文件浏览中，也不会参与扫描和播放',
                    labelWidth: 104,
                    control: Align(
                      alignment: Alignment.centerRight,
                      child: AppSwitch(value: isEnabled, onChanged: (value) => setModalState(() => isEnabled = value)),
                    ),
                  ),
                AppFormItem(
                  label: '连接测试',
                  subtitle: connectionTestResult ?? '验证是否能读取所选目录',
                  subtitleColor: connectionTestSucceeded == null
                      ? null
                      : connectionTestSucceeded!
                      ? AppColors.success(context)
                      : AppColors.danger(context),
                  labelWidth: 104,
                  control: Align(
                    alignment: Alignment.centerRight,
                    child: AppButton(
                      onPressed: isTestingConnection ? null : testConnection,
                      label: isTestingConnection ? '测试中' : '测试目录',
                      icon: Icons.wifi_tethering_outlined,
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.compact,
                      busy: isTestingConnection,
                    ),
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
            showFormError('请选择本地目录');
            return false;
          }
          if (!await Directory(directoryPath).exists()) {
            showFormError('所选目录不存在或不可访问');
            return false;
          }
          try {
            await _storageSourceService.save(
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
            showFormError('保存本地目录失败：$error');
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
            source == null
                ? '本地目录已添加'
                : clearedActiveSource
                ? '媒体源已保存，请重新打开以应用新配置'
                : '媒体源已保存',
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
    final existingCredentials = source == null ? null : await _storageSourceService.readCredentials(source.id);
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
        showFormError('请填写 SMB 主机地址');
        return null;
      }
      if (share.isEmpty || share.contains('/')) {
        showFormError('请填写共享名，不能包含斜杠');
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
      SmbStorageConnection? smbConnection;
      try {
        final connection = await StorageProviderRegistry.defaults().connect(
          draft,
          StorageCredentials(username: usernameController.text.trim(), password: passwordController.text),
        );
        smbConnection = connection is SmbStorageConnection ? connection : null;
        final entries = await connection.readDirectory('/');
        updateModal?.call(() {
          connectionTestSucceeded = true;
          connectionTestResult = '连接成功，可访问此目录（${entries.length} 项）';
        });
      } catch (error, stackTrace) {
        debugPrint('测试 SMB 连接失败: $error\n$stackTrace');
        updateModal?.call(() {
          connectionTestSucceeded = false;
          connectionTestResult = '连接失败：${_describeSmbConnectionError(error)}';
        });
      } finally {
        if (smbConnection != null) {
          await smbConnection.close();
        }
        updateModal?.call(() => isTestingConnection = false);
      }
    }

    try {
      final saved = await AppModal.show(
        context: context,
        title: source == null ? '添加 SMB 媒体源' : '编辑 SMB 媒体源',
        icon: Icons.lan_outlined,
        confirmLabel: source == null ? '添加' : '保存',
        content: StatefulBuilder(
          builder: (context, setModalState) {
            updateModal = setModalState;
            return AppFormGroup(
              children: [
                _buildStorageSourceFormItem(label: '名称', controller: nameController, placeholder: '例如：家庭 NAS'),
                _buildStorageSourceFormItem(label: '主机', controller: hostController, placeholder: '例如：192.168.1.20'),
                _buildStorageSourceFormItem(label: '共享名', controller: shareController, placeholder: '例如：Media'),
                _buildStorageSourceFormItem(label: '共享内路径', controller: rootPathController, placeholder: '/电影（可选）'),
                if (source != null)
                  AppFormItem(
                    label: '启用此媒体源',
                    subtitle: '停用后不会显示在文件浏览中，也不会参与扫描和播放',
                    labelWidth: 104,
                    control: Align(
                      alignment: Alignment.centerRight,
                      child: AppSwitch(value: isEnabled, onChanged: (value) => setModalState(() => isEnabled = value)),
                    ),
                  ),
                _buildStorageSourceFormItem(label: '用户名', controller: usernameController),
                _buildStorageSourceFormItem(
                  label: '密码',
                  controller: passwordController,
                  obscureText: !showPassword,
                  suffix: AppButton.icon(
                    onPressed: () => setModalState(() => showPassword = !showPassword),
                    icon: showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    tooltip: showPassword ? '隐藏密码' : '显示密码',
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.compact,
                  ),
                ),
                AppFormItem(
                  label: '连接测试',
                  subtitle: connectionTestResult ?? '使用当前填写的信息验证 SMB 连接',
                  subtitleColor: connectionTestSucceeded == null
                      ? null
                      : connectionTestSucceeded!
                      ? AppColors.success(context)
                      : AppColors.danger(context),
                  labelWidth: 104,
                  control: Align(
                    alignment: Alignment.centerRight,
                    child: AppButton(
                      onPressed: isTestingConnection ? null : testConnection,
                      label: isTestingConnection ? '测试中' : '测试连接',
                      icon: Icons.wifi_tethering_outlined,
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.compact,
                      busy: isTestingConnection,
                    ),
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
            await _storageSourceService.save(
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
            showFormError('保存 SMB 媒体源失败：$error');
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
            source == null
                ? 'SMB 媒体源已添加'
                : clearedActiveSource
                ? '媒体源已保存，请重新打开以应用新配置'
                : '媒体源已保存',
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
    final pathController = TextEditingController(text: _combineWebDavPaths(existingEndpoint?.path, source?.rootPath));
    final portController = TextEditingController(
      text: existingEndpoint?.hasPort == true ? '${existingEndpoint!.port}' : '',
    );
    final existingCredentials = source == null ? null : await _storageSourceService.readCredentials(source.id);
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
        showFormError('请先填写 WebDAV 主机地址');
        return;
      }
      final portText = portController.text.trim();
      final port = portText.isEmpty ? null : int.tryParse(portText);
      if (portText.isNotEmpty && (port == null || port < 1 || port > 65535)) {
        showFormError('端口应在 1 到 65535 之间');
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
        final connection = await StorageProviderRegistry.defaults().connect(
          StorageSource(
            id: source?.id ?? 'connection-test',
            name: nameController.text.trim().isEmpty ? host : nameController.text.trim(),
            type: StorageSourceType.webDav,
            endpoint: endpoint,
          ),
          StorageCredentials(username: usernameController.text.trim(), password: passwordController.text),
        );
        final entries = await connection.readDirectory('/');
        updateModal?.call(() {
          connectionTestSucceeded = true;
          connectionTestResult = '连接成功，可访问此目录（${entries.length} 项）';
        });
      } catch (error, stackTrace) {
        debugPrint('测试 WebDAV 连接失败: $error\n$stackTrace');
        updateModal?.call(() {
          connectionTestSucceeded = false;
          connectionTestResult = '连接失败：${_describeConnectionError(error)}';
        });
      } finally {
        updateModal?.call(() => isTestingConnection = false);
      }
    }

    try {
      final saved = await AppModal.show(
        context: context,
        title: source == null ? '添加 WebDAV 媒体源' : '编辑媒体源',
        icon: Icons.dns_outlined,
        confirmLabel: source == null ? '添加' : '保存',
        content: StatefulBuilder(
          builder: (context, setModalState) {
            updateModal = setModalState;
            return AppFormGroup(
              children: [
                _buildStorageSourceFormItem(label: '名称', controller: nameController, placeholder: '例如：家庭 NAS'),
                _buildStorageSourceFormItem(label: '主机', controller: hostController, placeholder: '例如：127.0.0.1'),
                _buildStorageSourceFormItem(label: 'WebDAV 路径', controller: pathController, placeholder: '/dav/quark'),
                _buildStorageSourceFormItem(
                  label: '端口',
                  controller: portController,
                  placeholder: useHttps ? '443（可选）' : '80（可选）',
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
                  AppFormItem(
                    label: '启用此媒体源',
                    subtitle: '停用后不会显示在文件浏览中，也不会参与扫描和播放',
                    labelWidth: 104,
                    control: Align(
                      alignment: Alignment.centerRight,
                      child: AppSwitch(value: isEnabled, onChanged: (value) => setModalState(() => isEnabled = value)),
                    ),
                  ),
                _buildStorageSourceFormItem(label: '用户名', controller: usernameController),
                _buildStorageSourceFormItem(
                  label: '密码',
                  controller: passwordController,
                  obscureText: !showPassword,
                  suffix: AppButton.icon(
                    onPressed: () => setModalState(() => showPassword = !showPassword),
                    icon: showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    tooltip: showPassword ? '隐藏密码' : '显示密码',
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.compact,
                  ),
                ),
                AppFormItem(
                  label: '连接测试',
                  subtitle: connectionTestResult ?? '使用当前填写的信息验证 WebDAV 连接',
                  subtitleColor: connectionTestSucceeded == null
                      ? null
                      : connectionTestSucceeded!
                      ? AppColors.success(context)
                      : AppColors.danger(context),
                  labelWidth: 104,
                  control: Align(
                    alignment: Alignment.centerRight,
                    child: AppButton(
                      onPressed: isTestingConnection ? null : testConnection,
                      label: isTestingConnection ? '测试中' : '测试连接',
                      icon: Icons.wifi_tethering_outlined,
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.compact,
                      busy: isTestingConnection,
                    ),
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
            showFormError('请填写 WebDAV 主机地址');
            return false;
          }
          final portText = portController.text.trim();
          final port = portText.isEmpty ? null : int.tryParse(portText);
          if (portText.isNotEmpty && (port == null || port < 1 || port > 65535)) {
            showFormError('端口应在 1 到 65535 之间');
            return false;
          }
          final path = _normalizeWebDavPath(pathController.text);
          final endpoint = Uri(scheme: useHttps ? 'https' : 'http', host: host, port: port, path: path).toString();
          final uri = Uri.tryParse(endpoint);
          if (uri == null || uri.host.isEmpty) {
            showFormError('请输入有效的 WebDAV 主机地址');
            return false;
          }
          try {
            await _storageSourceService.save(
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
            showFormError('保存媒体源失败：$error');
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
            source == null
                ? '媒体源已添加'
                : clearedActiveSource
                ? '媒体源已保存，请重新打开以应用新配置'
                : '媒体源已保存',
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
    if (message.contains('401')) return '认证失败，请检查用户名或密码';
    if (message.contains('403')) return '服务器拒绝访问，请检查目录权限';
    if (message.contains('404')) return '找不到该 WebDAV 路径';
    if (message.contains('HandshakeException') || message.contains('WRONG_VERSION_NUMBER')) {
      return 'HTTPS 设置不匹配，请确认服务器是否启用了 HTTPS';
    }
    if (message.contains('SocketException')) return '无法连接到服务器，请检查主机和端口';
    return '请检查主机、端口、路径和网络连接';
  }

  String _describeSmbConnectionError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('auth') || message.contains('logon') || message.contains('access denied')) {
      return '认证失败，请检查用户名或密码';
    }
    if (message.contains('not found') || message.contains('no such')) {
      return '找不到共享名或共享内路径';
    }
    if (message.contains('connection') || message.contains('socket') || message.contains('timeout')) {
      return '无法连接到 SMB 服务器，请检查主机、共享名和网络';
    }
    return '请检查主机、共享名、路径和登录信息';
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
      title: '删除媒体源？',
      message: '“${source.name}”的连接信息及其已扫描的本地媒体数据、播放进度和收藏状态将被删除，不会删除远程文件。',
      confirmLabel: '删除',
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (confirmed != true) return;
    try {
      final deletedFileCount = await _storageSourceService.deleteWithMedia(source.id);
      if (deletedFileCount == null) {
        AppMessage.error('媒体源不存在或已被删除');
        return;
      }
      if (!mounted) return;
      final fileBrowser = context.read<FileBrowserProvider>();
      if (fileBrowser.activeSource?.id == source.id) {
        fileBrowser.clearStorageSource();
      }
      await _loadStorageSources();
      if (mounted) {
        AppMessage.success('媒体源已删除，已清理 $deletedFileCount 个媒体文件');
      }
    } catch (error, stackTrace) {
      debugPrint('删除媒体源失败: $error\n$stackTrace');
      if (mounted) AppMessage.error('删除媒体源失败：$error');
    }
  }

  Widget _buildTmdbSettings(BuildContext context) {
    return Selector<AppSettingsProvider, bool>(
      selector: (context, provider) => provider.isSaving,
      builder: (context, isBusy, child) {
        return SettingsSection(
          title: '元数据',
          subtitle: '配置媒体信息的获取方式与网络访问',
          groups: [
            AppFormGroup(
              title: 'TMDB 配置',
              children: [
                SettingsTextField(
                  controller: _tmdbApiBaseUrlController,
                  keyboardType: TextInputType.url,
                  label: 'API 地址',
                  onFocusLost: _commitNetworkSettings,
                ),
                SettingsTextField(
                  controller: _tmdbApiKeyController,
                  obscureText: !_showTmdbApiKey,
                  label: 'API 密钥',
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
                  label: '使用代理访问 TMDB',
                  subtitle: '用于 TMDB API 和图片下载',
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
                    label: 'HTTP 代理',
                    onFocusLost: _commitNetworkSettings,
                  ),
                AppFormItem(
                  label: '连接状态',
                  subtitle: '检查当前 TMDB 配置是否可用',
                  labelWidth: null,
                  expandControl: false,
                  control: _SettingsActionButton(onPressed: isBusy ? null : _testTmdbConnection, label: '测试连接'),
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
      title: '播放',
      subtitle: '调整缓存、解码与字幕偏好',
      groups: [
        AppFormGroup(
          title: '缓存设置',
          children: [
            SettingsTextField(
              controller: _playbackCacheSizeMbController,
              keyboardType: TextInputType.number,
              label: '缓存大小',
              suffixText: 'MB',
              maxWidth: 120,
            ),
            SettingsTextField(
              controller: _playbackReadaheadSecondsController,
              keyboardType: TextInputType.number,
              label: '预读',
              suffixText: '秒',
              maxWidth: 120,
            ),
          ],
        ),
        AppFormGroup(
          title: '播放设置',
          children: [
            SettingsSwitchItem(
              label: '硬件解码',
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
          title: '字幕设置',
          children: [
            SettingsTextField(controller: _subtitleLanguagePriorityController, label: '默认字幕语言'),
            AppFormItem(
              label: '字幕大小',
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
      await _persistSettings(applyRuntime: shouldApplyRuntime, syncControllers: false);
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
      AppMessage.success('TMDB 连接成功');
    } else {
      AppMessage.error('TMDB 连接失败');
    }
  }

  Future<void> _confirmScanMediaSources() async {
    final confirmed = await AppModal.confirm(
      context: context,
      title: '扫描全部媒体源？',
      message: '这会递归扫描全部启用的媒体源，新增发现的视频，并清理已从来源删除的文件索引。配置 TMDB API Key 后还会自动刮削媒体信息。不会删除远程文件。',
      confirmLabel: '开始扫描',
      icon: Icons.manage_search_rounded,
    );

    if (confirmed != true || !mounted) return;

    final mediaLibraryProvider = context.read<MediaLibraryProvider>();
    final summary = await mediaLibraryProvider.scanMediaSources();
    if (!mounted) return;

    final error = mediaLibraryProvider.error;
    if (summary == null) {
      AppMessage.error(error ?? '扫描媒体源失败');
      return;
    }
    final message =
        '扫描完成：发现 ${summary.discoveredFileCount} 个视频，新增 ${summary.newFileCount} 个，移除 ${summary.removedFileCount} 个';
    final metadataMessage = switch ((summary.metadataMatchedCount, summary.metadataFailedCount)) {
      (final int matched, final int failed) => 'TMDB：已匹配 $matched 个，未匹配 $failed 个',
      _ => '未配置 TMDB API Key，已跳过元数据刮削',
    };
    if (error != null) {
      AppMessage.error('$message；$error');
    } else if (summary.failedSourceCount > 0) {
      AppMessage.error('$message；${summary.failedSourceCount} 个媒体源扫描失败；$metadataMessage');
    } else if (summary.metadataFailedCount case final failed? when failed > 0) {
      AppMessage.warning('$message；$metadataMessage');
    } else {
      AppMessage.success('$message；$metadataMessage');
    }
  }

  Future<void> _confirmClearLibrary() async {
    final confirmed = await AppModal.confirm(
      context: context,
      title: '清空媒体库？',
      message: '这会清空本地扫描文件、元数据、播放进度和收藏，不会删除 WebDAV 上的文件。',
      confirmLabel: '清空',
      icon: Icons.delete_sweep_rounded,
      destructive: true,
    );

    if (confirmed != true || !mounted) return;

    final mediaLibraryProvider = context.read<MediaLibraryProvider>();

    await mediaLibraryProvider.clearLibrary();
    if (!mounted) return;

    AppMessage.success('媒体库已清空');
  }

  Future<bool> _persistSettings({bool applyRuntime = false, bool syncControllers = true}) async {
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
      AppMessage.error(error);
      return false;
    }

    if (syncControllers) _syncControllers(settingsProvider);
    if (mounted && syncControllers) setState(() {});
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

  void _syncControllers(AppSettingsProvider settingsProvider) {
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
      message: visible ? '隐藏' : '显示',
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
