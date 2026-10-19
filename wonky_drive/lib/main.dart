import 'dart:async';

import 'package:wonky_app/wonky_app.dart';

import 'config/drive_app_config.dart';

/// Wonky Drive boots through the shared shell (suite 03, Drive 05 §1).
void main() {
  unawaited(WonkyShell.run(const DriveAppConfig()));
}
