import 'dart:io';

import 'package:wonky_server/src/platform/board/board_config.dart';
import 'package:yaml/yaml.dart';

/// The internal board AI keys for live runs: environment variables
/// `WONKY_INTERNAL_JEV_API_KEY` / `WONKY_INTERNAL_GEMINI_API_KEY`, else the
/// `development` section of `config/passwords.yaml`. Values are only
/// passed to the clients, never printed.
class LiveKeys {
  const LiveKeys(this.jev, this.gemini);

  final String? jev;
  final String? gemini;

  static LiveKeys load() {
    final env = Platform.environment;
    Map<dynamic, dynamic> dev = const {};
    final file = File('config/passwords.yaml');
    if (file.existsSync()) {
      final yaml = loadYaml(file.readAsStringSync());
      if (yaml is Map && yaml['development'] is Map) {
        dev = yaml['development'] as Map;
      }
    }
    String? pick(String envName, String password) {
      final v = env[envName] ?? dev[password];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    return LiveKeys(
      pick('WONKY_INTERNAL_JEV_API_KEY', BoardAiConfig.jevPassword),
      pick('WONKY_INTERNAL_GEMINI_API_KEY', BoardAiConfig.geminiPassword),
    );
  }

  /// A password reader for `JevGeminiBoardAi(password: …)`.
  String? password(String name) => switch (name) {
    BoardAiConfig.jevPassword => jev,
    BoardAiConfig.geminiPassword => gemini,
    _ => null,
  };
}
