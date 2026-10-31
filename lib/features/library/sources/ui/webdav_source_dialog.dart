// 【来源配置界面】编辑 WebDAV 地址、端口、路径及凭据并测试连接。
// 校验输入后调用来源服务，关闭时释放表单控制器。

import 'package:flutter/material.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/core/ui/components/input/form/app_form_switch_item.dart';
import 'package:mochi_player/features/library/sources/application/storage_sources_service.dart';
import 'package:mochi_player/features/library/sources/ui/source_form_fields.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

Future<void> showWebDavSourceDialog(
  BuildContext context, {
  required Future<void> Function() onSaved,
  StorageSource? source,
}) async {
  // 凭据读取可能失败或等待页面销毁；确认可展示后才创建需要释放的输入控制器。
  StorageCredentials? existingCredentials;
  try {
    if (source != null) {
      existingCredentials = await context.read<StorageSourcesService>().readCredentials(source.id);
    }
  } catch (error, stackTrace) {
    debugPrint('加载媒体源凭据失败: $error\n$stackTrace');
    if (context.mounted) AppMessage.error(context, context.l10n.sourcesLoadFailed);
    return;
  }
  if (!context.mounted) return;

  final nameController = TextEditingController(text: source?.name ?? '');
  final existingEndpoint = Uri.tryParse(source?.endpoint ?? '');
  final hostController = TextEditingController(text: existingEndpoint?.host ?? '');
  final pathController = TextEditingController(
    text: source == null ? '' : _combineWebDavPaths(existingEndpoint?.path, source.rootPath),
  );
  final portController = TextEditingController(
    text: existingEndpoint != null && existingEndpoint.host.isNotEmpty ? '${existingEndpoint.port}' : '',
  );
  final usernameController = TextEditingController(text: existingCredentials?.username ?? '');
  final passwordController = TextEditingController(text: existingCredentials?.password ?? '');

  var showPassword = false;
  // 本地 WebDAV 服务常使用 HTTP，例如 5244 端口；已有来源保留原协议，新来源默认不启用 HTTPS，有 TLS 的服务器可主动开启。
  var useHttps = existingEndpoint?.scheme == 'https';
  var isEnabled = source?.enabled ?? true;
  String? formError;
  String? connectionTestResult;
  bool? connectionTestSucceeded;
  var isTestingConnection = false;
  StateSetter? updateModal;
  var requiresBrowserReopen = false;

  void showFormError(String message) {
    updateModal?.call(() => formError = message);
  }

  // 测试和保存共用同一份校验与地址构造，避免两处规则逐渐偏离。
  StorageSource? buildSourceDraft() {
    final host = hostController.text.trim();
    if (host.isEmpty) {
      showFormError(context.l10n.webdavHostRequired);
      return null;
    }
    final portText = portController.text.trim();
    if (portText.isEmpty) {
      showFormError(context.l10n.webdavPortRequired);
      return null;
    }
    final port = int.tryParse(portText);
    if (port == null || port < 1 || port > 65535) {
      showFormError(context.l10n.portRangeError);
      return null;
    }
    Uri endpoint;
    try {
      endpoint = Uri(
        scheme: useHttps ? 'https' : 'http',
        host: host,
        port: port,
        path: _normalizeWebDavPath(pathController.text),
      );
    } on FormatException {
      showFormError(context.l10n.webdavHostInvalid);
      return null;
    }
    if (endpoint.host.isEmpty) {
      showFormError(context.l10n.webdavHostInvalid);
      return null;
    }
    return StorageSource(
      id: source?.id ?? 'connection-test',
      name: nameController.text.trim().isEmpty ? host : nameController.text.trim(),
      type: StorageSourceType.webDav,
      endpoint: endpoint.toString(),
      rootPath: '/',
      enabled: isEnabled,
    );
  }

  Future<void> testConnection() async {
    final draft = buildSourceDraft();
    if (draft == null) return;
    updateModal?.call(() {
      formError = null;
      isTestingConnection = true;
      connectionTestResult = null;
      connectionTestSucceeded = null;
    });
    try {
      await context.read<StorageSourcesService>().testConnection(
        draft,
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
        connectionTestResult = context.l10n.connectionFailedDetail(_describeConnectionError(context, error));
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
              sourceFormField(
                label: context.l10n.name,
                controller: nameController,
                placeholder: context.l10n.nasNameExample,
              ),
              sourceFormField(
                label: context.l10n.host,
                controller: hostController,
                placeholder: context.l10n.webdavHostExample,
              ),
              sourceFormField(label: context.l10n.webdavPath, controller: pathController, placeholder: '/dav'),
              sourceFormField(
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
                AppFormSwitchItem(
                  label: context.l10n.enableSource,
                  subtitle: context.l10n.disableSourceDescription,
                  value: isEnabled,
                  onChanged: (value) => setModalState(() => isEnabled = value),
                ),
              sourceFormField(
                label: context.l10n.username,
                controller: usernameController,
                placeholder: context.l10n.webdavUsernameHint,
              ),
              sourceFormField(
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
                subtitleColor: connectionTestSucceeded == true ? AppColors.success(context) : AppColors.danger(context),
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
        final draft = buildSourceDraft();
        if (draft == null) return false;
        try {
          requiresBrowserReopen = await context.read<StorageSourcesService>().save(
            StorageSource(
              id: source?.id ?? const Uuid().v4(),
              name: draft.name,
              type: StorageSourceType.webDav,
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
          debugPrint('保存媒体源失败: $error\n$stackTrace');
          if (!context.mounted) return false;
          showFormError(context.l10n.sourceSaveFailed);
          return false;
        }
      },
    );
    updateModal = null;
    if (saved == true && context.mounted) {
      await onSaved();
      if (context.mounted) {
        AppMessage.success(
          context,
          source == null
              ? context.l10n.sourceAdded
              : requiresBrowserReopen
              ? context.l10n.sourceSavedReopen
              : context.l10n.sourceSaved,
        );
      }
    }
  } finally {
    updateModal = null;
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

String _describeConnectionError(BuildContext context, Object error) {
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

String _combineWebDavPaths(String? endpointPath, String? rootPath) {
  final endpoint = _normalizeWebDavPath(endpointPath ?? '/');
  final root = _normalizeWebDavPath(rootPath ?? '/');
  if (endpoint == '/') return root;
  if (root == '/') return endpoint;
  return '$endpoint$root';
}
