import 'dart:convert';
import 'dart:io';

/// Keep translated resources complete instead of silently falling back to English.
void main() {
  final directory = Directory('lib/l10n');
  final template = jsonDecode(File('${directory.path}/app_en.arb').readAsStringSync()) as Map<String, dynamic>;
  final expected = template.keys.where((key) => !key.startsWith('@')).toSet();
  final failures = <String>[];
  for (final file in directory.listSync().whereType<File>().where((file) => file.path.endsWith('.arb'))) {
    final resource = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final actual = resource.keys.where((key) => !key.startsWith('@')).toSet();
    final missing = expected.difference(actual);
    final extra = actual.difference(expected);
    if (missing.isNotEmpty || extra.isNotEmpty) {
      failures.add('${file.path}: missing $missing; unknown $extra');
    }
    for (final key in expected.intersection(actual)) {
      if (resource[key] is! String || (resource[key] as String).isEmpty) {
        failures.add('${file.path}: empty or invalid $key');
      }
      final metadata = template['@$key'] as Map<String, dynamic>?;
      final placeholders = metadata?['placeholders'] as Map<String, dynamic>? ?? const {};
      for (final name in placeholders.keys) {
        if (!RegExp('\\{${RegExp.escape(name)}(?:\\}|\\s*,)').hasMatch(resource[key] as String)) {
          failures.add('${file.path}: missing placeholder $name in $key');
        }
      }
    }
  }
  if (failures.isNotEmpty) {
    stderr.writeln(failures.join('\n'));
    exitCode = 1;
  } else {
    stdout.writeln('Localization resources are complete (${expected.length} messages).');
  }
}
