// ignore_for_file: implementation_imports, invalid_use_of_internal_member

import 'dart:async';

// The pinned SDK initializes the Win32 windowing owner before flutter_test
// installs its test owner. flutter_tester does not export that native API.
// Unit/widget tests use injected WindowService fakes; real windows are covered
// by integration_test/windowing_smoke.dart running with the production runner.
import 'package:flutter/src/foundation/_features.dart' show isWindowingEnabled;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  isWindowingEnabled = false;
  await testMain();
}
