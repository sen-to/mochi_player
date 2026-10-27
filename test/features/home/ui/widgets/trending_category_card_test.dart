// 【行为测试】验证展示一类趋势条目及其横向内容。
// 测试对象的职责边界：接收已加载条目，图片加载使用共享缓存。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mochi_player/features/home/ui/widgets/trending_category_card.dart';
import 'package:mochi_player/l10n/l10n.dart';

void main() {
  testWidgets('shows row skeletons instead of hiding trend content while loading', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TrendingCategoryCard(
            config: TrendingCategoryCardConfig(
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
