import 'package:serverpod/serverpod.dart';

import '../../sheets/revlog/sheets_rev_binding.dart';
import '../../slides/revlog/slides_rev_binding.dart';
import '../common/models.dart';
import '../common/time.dart';
import '../config/wonky_config.dart';

/// Protocol information checked by clients on connect (specs/01 §7).
class MetaEndpoint extends Endpoint {
  static String? _hash;

  Future<ProtocolInfo> getInfo(Session session) async {
    final c = WonkyConfig.current;
    final redis = session.serverpod.redisController;
    return ProtocolInfo(
      redisEnabled: redis != null,
      redisConnected: redis != null && await _ping(redis),
      serverVersion: c.serverVersion,
      minClientVersion: c.minClientVersion,
      revSchemaHash: _hash ??=
          'sheets:${SheetsRevBinding.instance.schema.hash},'
          'slides:${SlidesRevBinding.instance.schema.hash}',
      runMode: session.serverpod.runMode,
      features: FeatureFlags(
        ai: c.aiEnabled,
        scripting: c.scriptingEnabled,
        mcpUiBridge: c.mcpUiBridgeEnabled,
        experimentalCharts: c.experimentalCharts,
      ),
      limits: ServerLimits(
        maxCellsPerSpreadsheet: c.maxCellsPerSpreadsheet,
        maxSheetsPerSpreadsheet: c.maxSheetsPerSpreadsheet,
        maxDocumentChars: c.maxDocumentChars,
        maxImageUploadBytes: c.maxImageUploadBytes,
        maxImportUploadBytes: c.maxImportUploadBytes,
        scriptTimeoutMs: c.scriptTimeoutMs,
        maxFileUploadBytes: c.maxFileUploadBytes,
        quotaBytesPerUser: c.quotaBytesPerUser,
      ),
      serverTime: nowUtc(),
    );
  }

  /// Whether Redis answers a ping, cached for [_pingTtl]: every open app
  /// calls `getInfo` as its connectivity heartbeat (every 15 s), which must
  /// not become a Redis command per user.
  static Future<bool> _ping(RedisController redis) {
    final now = DateTime.now();
    final cached = _pinged;
    if (cached != null && now.difference(cached.$1) < _pingTtl) {
      return cached.$2;
    }
    final result = () async {
      try {
        return await redis.ping().timeout(const Duration(seconds: 1));
      } catch (_) {
        return false;
      }
    }();
    _pinged = (now, result);
    return result;
  }

  static const _pingTtl = Duration(seconds: 30);
  static (DateTime, Future<bool>)? _pinged;
}
