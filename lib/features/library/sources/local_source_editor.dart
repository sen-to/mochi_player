import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mochi_player/core/domain/storage/models.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/core/ui/components/input/form/settings_switch_item.dart';
import 'package:mochi_player/features/library/browser/file_browser_provider.dart';
import 'package:mochi_player/features/library/sources/source_editor_fields.dart';
import 'package:mochi_player/features/library/sources/storage_sources_service.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

Future<void> showLocalSourceEditor(
  BuildContext context, {
  required Future<void> Function() onSaved,
  StorageSource? source,
  String? initialDirectory,
}) async {
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
    final selected = await pickLocalDirectory(context, initialDirectory: directoryPath.isEmpty ? null : directoryPath);
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
      await context.read<StorageSourcesService>().testConnection(
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
              sourceEditorField(
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
                subtitleColor: connectionTestSucceeded == true ? AppColors.success(context) : AppColors.danger(context),
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
          if (!context.mounted) return false;
          showFormError(context.l10n.folderUnavailable);
          return false;
        }
        try {
          await context.read<StorageSourcesService>().save(
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
          if (!context.mounted) return false;
          showFormError(context.l10n.localFolderSaveFailed);
          return false;
        }
      },
    );
    updateModal = null;
    if (saved == true && context.mounted) {
      var clearedActiveSource = false;
      if (source != null && context.mounted) {
        final fileBrowser = context.read<FileBrowserProvider>();
        if (fileBrowser.activeSource?.id == source.id) {
          fileBrowser.clearStorageSource();
          clearedActiveSource = true;
        }
      }
      await onSaved();
      if (context.mounted) {
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
    updateModal = null;
    nameController.dispose();
  }
}
