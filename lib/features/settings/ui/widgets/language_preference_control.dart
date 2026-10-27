// 【设置界面】展示跟随系统、中文与英文的语言选择。
// 通过语言 Provider 更新偏好，不自行保存配置。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/l10n/application/app_locale_provider.dart';
import 'package:mochi_player/l10n/l10n.dart';
import 'package:provider/provider.dart';

class LanguagePreferenceControl extends StatelessWidget {
  const LanguagePreferenceControl({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 144,
    child: AppSelect<AppLanguage>(
      value: context.watch<AppLocaleProvider>().language,
      options: [
        AppSelectOption(value: AppLanguage.system, label: context.l10n.languageSystem),
        AppSelectOption(value: AppLanguage.zh, label: context.l10n.languageChinese),
        AppSelectOption(value: AppLanguage.en, label: context.l10n.languageEnglish),
      ],
      onChanged: (language) => unawaited(
        context.read<AppLocaleProvider>().setLanguage(language).catchError((Object error) {
          if (context.mounted) AppMessage.error(context, context.l10n.languageSaveFailed);
        }),
      ),
    ),
  );
}
