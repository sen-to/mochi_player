// 【设置界面】组合外观、媒体源、元数据与播放偏好表单。
// 通过 Provider 保存偏好；跨功能联动由应用入口连接。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/core/ui/components/input/form/app_form_switch_item.dart';
import 'package:mochi_player/features/settings/application/app_settings_provider.dart';
import 'package:mochi_player/features/settings/application/theme_provider.dart';
import 'package:mochi_player/features/settings/domain/app_settings.dart';
import 'package:mochi_player/features/settings/ui/widgets/language_preference_control.dart';
import 'package:mochi_player/features/settings/ui/widgets/settings_section.dart';
import 'package:mochi_player/features/settings/ui/widgets/settings_text_field.dart';
import 'package:mochi_player/features/settings/ui/widgets/theme_preference_controls.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.mediaSourcesPanel});

  final Widget mediaSourcesPanel;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

enum _SettingsTab { general, mediaSource, metadata, playback }

class _SettingsPageState extends State<SettingsPage> {
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

  List<TextEditingController> get _settingsControllers => [
    _tmdbApiKeyController,
    _tmdbApiBaseUrlController,
    _tmdbProxyUrlController,
    _playbackCacheSizeMbController,
    _playbackReadaheadSecondsController,
    _subtitleLanguagePriorityController,
  ];

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
      _SettingsTab.mediaSource => _buildMediaSourceSettings(context),
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

  Widget _buildMediaSourceSettings(BuildContext context) => SettingsSection(
    title: context.l10n.mediaSources,
    subtitle: context.l10n.mediaSourcesDescription,
    groups: [widget.mediaSourcesPanel],
  );

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
                AppFormSwitchItem(
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
                  control: AppButton(
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.compact,
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
            AppFormSwitchItem(
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
      await _persistSettings(applyRuntime: shouldApplyRuntime, syncServices: false);
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
