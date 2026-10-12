import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/app/presentation/navigation/app_destination.dart';
import 'package:mochi_player/app/presentation/widgets/sidebar.dart';
import 'package:mochi_player/core/ui/theme/app_theme.dart';
import 'package:mochi_player/l10n/l10n.dart';

void main() {
  testWidgets('selects destinations by identity instead of numeric indexes', (tester) async {
    var selectedDestination = AppDestination.home;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme,
        home: StatefulBuilder(
          builder: (context, setState) => Sidebar(
            selectedDestination: selectedDestination,
            onDestinationSelected: (destination) {
              setState(() => selectedDestination = destination);
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('电影'));
    await tester.pump();

    expect(selectedDestination, AppDestination.movies);
  });
}
