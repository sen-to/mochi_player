import 'package:flutter/material.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/core/ui/components/input/form/settings_switch_item.dart';
import 'package:mochi_player/features/library/sources/source_editor_fields.dart';
import 'package:mochi_player/features/library/sources/storage_sources_service.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

Future<void> showWebDavSourceEditor(
  BuildContext context, {
  required Future<void> Function() onSaved,
  StorageSource? source,
}) async {
  final nameController = TextEditingController(text: source?.name ?? '');
  final existingEndpoint = Uri.tryParse(source?.endpoint ?? '');
  final hostController = TextEditingController(text: existingEndpoint?.host ?? '');
  final pathController = TextEditingController(
    text: source == null ? '' : _combineWebDavPaths(existingEndpoint?.path, source.rootPath),
  );
  final portController = TextEditingController(
    text: existingEndpoint != null && existingEndpoint.host.isNotEmpty ? '${existingEndpoint.port}' : '',
  );
  final existingCredentials = source == null
      ? null
      : await context.read<StorageSourcesService>().readCredentials(source.id);
  final usernameController = TextEditingController(text: existingCredentials?.username ?? '');
  final passwordController = TextEditingController(text: existingCredentials?.password ?? '');
  if (!context.mounted) {
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
  var requiresBrowserReopen = false;

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
      await context.read<StorageSourcesService>().testConnection(
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
              sourceEditorField(
                label: context.l10n.name,
                controller: nameController,
                placeholder: context.l10n.nasNameExample,
              ),
              sourceEditorField(
                label: context.l10n.host,
                controller: hostController,
                placeholder: context.l10n.webdavHostExample,
              ),
              sourceEditorField(label: context.l10n.webdavPath, controller: pathController, placeholder: '/dav'),
              sourceEditorField(
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
              sourceEditorField(
                label: context.l10n.username,
                controller: usernameController,
                placeholder: context.l10n.webdavUsernameHint,
              ),
              sourceEditorField(
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
          requiresBrowserReopen = await context.read<StorageSourcesService>().save(
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
