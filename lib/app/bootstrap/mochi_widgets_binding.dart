import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Temporary Windows workaround for flutter/flutter#175041.
///
/// Keep the shared engine from generating semantics updates for any view until
/// the native AXTree crash is fixed and verified. Other platforms retain the
/// normal framework behavior.
class MochiWidgetsBinding extends WidgetsFlutterBinding {
  @override
  bool get semanticsEnabled {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) return false;
    return super.semanticsEnabled;
  }
}
