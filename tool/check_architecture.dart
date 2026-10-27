// 【架构检查】验证中文文件说明、界面归属及核心依赖方向。
// 只检查手写 Dart 源码，生成代码由对应生成工具维护。

import 'dart:io';

bool _isGenerated(String path) =>
    path.contains('/generated/') || path.endsWith('.g.dart') || path.endsWith('.freezed.dart');

void main() {
  final problems = <String>[];
  var checked = 0;
  final featureDependencies = <String, Set<String>>{};
  final chinese = RegExp(r'[\u4e00-\u9fff]');
  final dependencies = RegExp(r"^(?:import|export|part)\s+'([^']+)'", multiLine: true);
  final widgetDeclaration = RegExp(r'extends\s+(?:StatefulWidget|StatelessWidget|State<)');

  for (final root in ['lib', 'test', 'tool', 'integration_test']) {
    for (final file in Directory(root).listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll('\\', '/');
      if (_isGenerated(path)) continue;
      if (path.endsWith('.drift')) {
        final sql = file.readAsStringSync();
        if (RegExp(r'WITH\s+(MediaFile|Movie|TVShow|Season|Episode)\b').hasMatch(sql) || sql.contains('/domain/')) {
          problems.add('$path：数据库定义不得直接映射业务模型，应生成独立 DO。');
        }
        continue;
      }
      if (!path.endsWith('.dart')) continue;
      checked++;
      final source = file.readAsStringSync();
      final opening = source.split('\n').take(2).toList();
      if (opening.length != 2 ||
          !opening.first.startsWith('// 【') ||
          opening.any((line) => !line.startsWith('// ') || !chinese.hasMatch(line))) {
        problems.add('$path：开头两行需要中文职责及协作边界说明。');
      }
      if (path.startsWith('lib/features/')) {
        if (path.contains('/presentation/') || path.contains('/infrastructure/') || path.contains('/contracts/')) {
          problems.add('$path：统一使用 ui / application / domain / data 职责目录。');
        }
        if (widgetDeclaration.hasMatch(source) && !path.contains('/ui/')) {
          problems.add('$path：功能页面及组件应归入所属功能的 ui。');
        }
      }
      if (path.startsWith('lib/')) {
        if (path.contains('/presentation/') || path.contains('/infrastructure/') || path.contains('/contracts/')) {
          problems.add('$path：职责目录只使用 ui / application / domain / data。');
        }
        if (path.contains('/domain/') && RegExp(r'\b(fromJson|toJson|toInsertable)\s*\(').hasMatch(source)) {
          problems.add('$path：领域模型不得包含外部序列化或数据库映射。');
        }
        if (source.contains('@UseRowClass(')) problems.add('$path：数据库必须生成独立 DO，禁止复用业务模型作行类型。');
        if (path.endsWith('_provider.dart') && !path.contains('/application/')) {
          problems.add('$path：Provider 统一放在 application，负责界面状态和用例入口。');
        }
        if (path.contains('/domain/') && RegExp(r'class\s+\w+Mapper\b').hasMatch(source)) {
          problems.add('$path：领域模型不混入边界 Mapper。');
        }
        if (path.endsWith('_vo.dart') && RegExp(r'(class\s+\w+Mapper\b|factory\s+\w+VO\.)').hasMatch(source)) {
          problems.add('$path：VO 只描述数据，边界转换应独立到 Mapper。');
        }
      }
      for (final match in dependencies.allMatches(source)) {
        final dependency = match.group(1)!;
        if (path.startsWith('lib/') &&
            (path.contains('/application/') || path.contains('/domain/')) &&
            (dependency == 'dart:io' ||
                dependency.startsWith('package:drift/') ||
                dependency.startsWith('package:dio/') ||
                dependency.startsWith('package:shared_preferences/'))) {
          problems.add('$path：业务和模型不得直接依赖数据访问 SDK：$dependency');
        }
        final uri = Uri.parse(dependency);
        final Uri target;
        if (dependency.startsWith('package:mochi_player/')) {
          target = Directory.current.uri.resolve('lib/${dependency.substring('package:mochi_player/'.length)}');
        } else if (!uri.hasScheme) {
          target = file.absolute.uri.resolveUri(uri);
        } else {
          continue;
        }
        if (!File.fromUri(target).existsSync()) problems.add('$path：引用文件不存在：$dependency');
        final targetPath = target.toFilePath().replaceAll('\\', '/');
        final featureRoot = '${Directory.current.path.replaceAll('\\', '/')}/lib/features/';
        if (path.startsWith('lib/features/') && targetPath.startsWith(featureRoot)) {
          final from = path.split('/')[2];
          final to = targetPath.substring(featureRoot.length).split('/').first;
          if (from != to) featureDependencies.putIfAbsent(from, () => <String>{}).add(to);
        }
        if (path.startsWith('lib/core/') &&
            (targetPath.contains('/lib/features/') || targetPath.contains('/lib/app/'))) {
          problems.add('$path：core 不得反向依赖功能或应用组装：$dependency');
        }
        if (path.startsWith('lib/')) {
          if ((path.contains('/application/') || path.contains('/domain/')) &&
              targetPath.contains('/lib/') &&
              targetPath.contains('/data/')) {
            problems.add('$path：application / domain 不得依赖具体数据实现：$dependency');
          }
          if (path.contains('/domain/') &&
              targetPath.contains('/lib/') &&
              (targetPath.contains('/application/') || targetPath.contains('/ui/'))) {
            problems.add('$path：domain 不得反向依赖用例或界面：$dependency');
          }
          if (path.contains('/data/') && targetPath.contains('/lib/') && targetPath.contains('/ui/')) {
            problems.add('$path：数据适配不得依赖界面：$dependency');
          }
          // 共享图片组件是渲染资源的适配边界，具体缓存实现不进入功能 UI。
          if (path.contains('/ui/') &&
              path != 'lib/core/ui/images/media_network_image.dart' &&
              targetPath.contains('/lib/') &&
              targetPath.contains('/data/')) {
            problems.add('$path：界面通过应用入口或共享资源组件访问后端：$dependency');
          }
        }
      }
    }
  }
  final visited = <String>{};
  final active = <String>[];
  void visit(String feature) {
    if (active.contains(feature)) {
      problems.add('功能循环依赖：${[...active.skip(active.indexOf(feature)), feature].join(' → ')}');
      return;
    }
    if (!visited.add(feature)) return;
    active.add(feature);
    for (final dependency in featureDependencies[feature] ?? <String>{}) {
      visit(dependency);
    }
    active.removeLast();
  }

  for (final feature in featureDependencies.keys) {
    visit(feature);
  }
  if (problems.isNotEmpty) {
    stderr.writeln(problems.join('\n'));
    exitCode = 1;
    return;
  }
  stdout.writeln('架构检查通过：$checked 个手写 Dart 文件的中文说明、引用及依赖边界有效。');
}
