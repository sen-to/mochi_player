// 【来源配置界面】编辑 SMB 主机、共享、根路径与凭据并测试连接。
// 保存交给来源服务，迟到测试结果不更新已关闭弹窗。

import 'package:flutter/material.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/domain/storage/smb_source_location.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/core/ui/components/input/form/app_form_switch_item.dart';
import 'package:mochi_player/features/library/sources/application/storage_sources_service.dart';
import 'package:mochi_player/features/library/sources/ui/source_form_fields.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

Future<void> showSmbSourceDialog(
  BuildContext context, {
  required Future<void> Function() onSaved,
  StorageSource? source,
}) async {
  final endpoint = Uri.tryParse(source?.endpoint ?? '');
  final nameController = TextEditingController(text: source?.name ?? '');
  final hostController = TextEditingController(text: endpoint?.host ?? '');
  final shareController = TextEditingController(
    text: endpoint?.pathSegments.where((segment) => segment.isNotEmpty).firstOrNull ?? '',
  );
  final rootPathController = TextEditingController(text: source?.rootPath ?? '/');
  final existingCredentials = source == null
      ? null
      : await context.read<StorageSourcesService>().readCredentials(source.id);
  final usernameController = TextEditingController(text: existingCredentials?.username ?? '');
  final passwordController = TextEditingController(text: existingCredentials?.password ?? '');
  if (!context.mounted) {
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
  var requiresBrowserReopen = false;

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
      await context.read<StorageSourcesService>().testConnection(
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
        connectionTestResult = context.l10n.connectionFailedDetail(_describeSmbConnectionError(context, error));
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
              sourceFormField(
                label: context.l10n.name,
                controller: nameController,
                placeholder: context.l10n.nasNameExample,
              ),
              sourceFormField(
                label: context.l10n.host,
                controller: hostController,
                placeholder: context.l10n.smbHostExample,
              ),
              sourceFormField(
                label: context.l10n.shareName,
                controller: shareController,
                placeholder: context.l10n.shareNameExample,
              ),
              sourceFormField(
                label: context.l10n.sharePath,
                controller: rootPathController,
                placeholder: context.l10n.sharePathExample,
              ),
              if (source != null)
                AppFormSwitchItem(
                  label: context.l10n.enableSource,
                  subtitle: context.l10n.disableSourceDescription,
                  value: isEnabled,
                  onChanged: (value) => setModalState(() => isEnabled = value),
                ),
              sourceFormField(label: context.l10n.username, controller: usernameController),
              sourceFormField(
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
        final draft = draftSource();
        if (draft == null) return false;
        try {
          requiresBrowserReopen = await context.read<StorageSourcesService>().save(
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
          if (!context.mounted) return false;
          showFormError(context.l10n.smbSourceSaveFailed);
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
              ? context.l10n.smbSourceAdded
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
    shareController.dispose();
    rootPathController.dispose();
    usernameController.dispose();
    passwordController.dispose();
  }
}

String _describeSmbConnectionError(BuildContext context, Object error) {
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
