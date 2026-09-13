import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/core/ui/app_ui.dart';
import 'package:mochi_player/features/library/presentation/widgets/media_card.dart';

void main() {
  testWidgets('renders media metadata without a separate progress flag', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: SizedBox(
            width: 200,
            height: 300,
            child: MediaCard(title: '测试电影', subtitle: '2026', rating: 8.6, progress: 1.5),
          ),
        ),
      ),
    );

    expect(find.text('测试电影'), findsNWidgets(2));
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('8.6'), findsOneWidget);
    expect(tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox)).widthFactor, 1);
  });

  testWidgets('omits playback progress when no value is supplied', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: SizedBox(width: 200, height: 300, child: MediaCard(title: '测试电影')),
        ),
      ),
    );

    expect(find.byType(FractionallySizedBox), findsNothing);
  });
}
