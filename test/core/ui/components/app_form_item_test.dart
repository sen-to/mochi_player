import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/settings/presentation/widgets/settings_switch_item.dart';
import 'package:mochi_player/l10n/l10n.dart';

void main() {
  testWidgets('switch descriptions use remaining width and grow without hiding text', (tester) async {
    for (final locale in [const Locale('zh'), const Locale('en')]) {
      for (final scale in [1.0, 1.5]) {
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 300,
                    child: Builder(
                      builder: (context) => SettingsSwitchItem(
                        label: context.l10n.enableSource,
                        subtitle: context.l10n.disableSourceDescription,
                        value: true,
                        onChanged: (_) {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        final context = tester.element(find.byType(SettingsSwitchItem));
        final description = find.text(context.l10n.disableSourceDescription);
        final descriptionRect = tester.getRect(description);
        final switchRect = tester.getRect(find.byType(AppSwitch));
        final rowRect = tester.getRect(find.byType(AppFormItem));
        expect(descriptionRect.width, greaterThan(104));
        expect(descriptionRect.right, lessThan(switchRect.left));
        expect(descriptionRect.bottom, lessThanOrEqualTo(rowRect.bottom));
        expect(tester.widget<Text>(description).maxLines, isNull);
        expect(tester.widget<Text>(description).overflow, isNot(TextOverflow.ellipsis));
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('connection results stay under the title beside a centered button', (tester) async {
    const details =
        'Connection failed: the server could not be reached. Check the address, port and network connection.';

    for (final scale in [1.0, 1.5]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: const Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 360,
                  child: AppFormItem(
                    label: 'Connection test',
                    labelWidth: null,
                    subtitle: details,
                    expandControl: false,
                    control: TextButton(onPressed: null, child: Text('Test')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final detailRect = tester.getRect(find.text(details));
      final buttonRect = tester.getRect(find.byType(TextButton));
      final detailText = tester.widget<Text>(find.text(details));
      final titleRect = tester.getRect(find.text('Connection test'));
      final rowRect = tester.getRect(find.byType(AppFormItem));
      expect(detailRect.top, greaterThan(titleRect.bottom));
      expect(detailRect.left, titleRect.left);
      expect(detailRect.right, lessThan(buttonRect.left));
      expect(buttonRect.center.dy, closeTo(rowRect.center.dy, 0.01));
      expect(detailRect.width, greaterThan(104));
      expect(detailRect.height, greaterThan(tester.getSize(find.text('Test')).height * 2));
      expect(detailText.maxLines, isNull);
      expect(detailText.overflow, isNot(TextOverflow.ellipsis));
      expect(tester.takeException(), isNull);
    }
  });
}
