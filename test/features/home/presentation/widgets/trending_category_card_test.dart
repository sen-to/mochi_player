import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/features/home/presentation/widgets/trending_category_card.dart';

void main() {
  testWidgets('shows row skeletons instead of hiding trend content while loading', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TrendingCategoryCard(
            config: TrendingCardConfig(
              icon: Icons.local_fire_department_rounded,
              iconColor: Colors.orange,
              title: '热门电影',
              subtitle: '全球前三',
            ),
            items: [],
            isLoading: true,
          ),
        ),
      ),
    );

    expect(find.text('热门电影'), findsOneWidget);
    expect(find.text('暂无数据'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
