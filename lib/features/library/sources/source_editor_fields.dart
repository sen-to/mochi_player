import 'package:flutter/material.dart';
import 'package:mochi_player/core/platform/window_service.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:provider/provider.dart';

Widget sourceEditorField({
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

Future<String?> pickLocalDirectory(BuildContext context, {String? initialDirectory}) async {
  try {
    return await context.read<WindowService>().pickDirectory(initialDirectory: initialDirectory);
  } catch (error) {
    debugPrint('打开目录选择器失败: $error');
    if (context.mounted) AppMessage.error(context, context.l10n.directorySelectionFailed);
    return null;
  }
}
