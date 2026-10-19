import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:yaml/yaml.dart';

/// The one reader of `config/<runMode>.yaml`'s `wonky:` section (CQ-33),
/// shared by `WonkyConfig`, `AiConfig`, `McpConfig` and `BoardConfig`.
///
/// - The run mode is the running server's; without a server (unit tests,
///   tools) it is `development`. A run mode Wonky has no configuration for
///   fails loudly instead of silently using the development settings.
/// - A missing file is an empty configuration (Serverpod Cloud uploads no
///   `config/*.yaml`; production defaults live in code).
/// - The file is parsed once per path.
abstract final class WonkyConfigFile {
  /// The run modes with a `config/<runMode>.yaml`.
  static const knownRunModes = {
    ServerpodRunMode.development,
    ServerpodRunMode.test,
    ServerpodRunMode.staging,
    ServerpodRunMode.production,
  };

  static final Map<String, Map<dynamic, dynamic>> _parsed = {};

  /// The running server's run mode (`development` without a server).
  /// Throws [StateError] for a run mode not in [knownRunModes].
  static String runMode() {
    String mode;
    try {
      mode = Serverpod.instance.runMode;
    } on StateError {
      // No server: unit tests and tools.
      return ServerpodRunMode.development;
    }
    return checkRunMode(mode);
  }

  /// [mode] if it is in [knownRunModes], else throws [StateError].
  static String checkRunMode(String mode) {
    if (!knownRunModes.contains(mode)) {
      throw StateError(
        'Unknown run mode "$mode": Wonky has configuration for '
        '${knownRunModes.join(', ')} (config/<runMode>.yaml).',
      );
    }
    return mode;
  }

  /// The `wonky:` map of `config/<runMode>.yaml` under [directory]
  /// (default: the working directory); empty without the file.
  static Map<dynamic, dynamic> wonky({String? runMode, Directory? directory}) {
    final mode = runMode == null
        ? WonkyConfigFile.runMode()
        : checkRunMode(runMode);
    final path = '${(directory ?? Directory.current).path}/config/$mode.yaml';
    return _parsed[path] ??= () {
      final file = File(path);
      if (!file.existsSync()) return const <dynamic, dynamic>{};
      final yaml = loadYaml(file.readAsStringSync());
      return yaml is Map && yaml['wonky'] is Map
          ? yaml['wonky'] as Map
          : const <dynamic, dynamic>{};
    }();
  }

  /// The `wonky: <name>:` map (empty when missing).
  static Map<dynamic, dynamic> section(
    String name, {
    String? runMode,
    Directory? directory,
  }) {
    final s = wonky(runMode: runMode, directory: directory)[name];
    return s is Map ? s : const <dynamic, dynamic>{};
  }

  /// Forgets parsed files (tests).
  static void clear() => _parsed.clear();
}
