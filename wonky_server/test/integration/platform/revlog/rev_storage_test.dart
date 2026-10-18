@Tags(['integration'])
library;

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/revlog/rev_storage.dart';

import '../../../support/wonky_serverpod.dart';

void main() {
  withWonkyServerpod('Given the RevLog tables', (sessionBuilder, _) {
    late Session session;
    setUp(() => session = sessionBuilder.build());

    Future<List<String>> options(String table) async {
      final rows = await session.db.unsafeQuery(
        'SELECT reloptions FROM pg_class WHERE relname = @t',
        parameters: QueryParameters.named({'t': table}),
      );
      return (rows.first[0] as List?)?.cast<String>() ?? const [];
    }

    test('when the storage parameters are ensured then the cell table keeps '
        'free space for in-place updates, and ensuring again changes '
        'nothing', () async {
      await session.db.unsafeExecute('ALTER TABLE cell RESET (fillfactor)');

      final first = await RevStorage.ensure(session);
      final second = await RevStorage.ensure(session);

      expect(first, ['cell']);
      expect(second, isEmpty);
      expect(await options('cell'), contains('fillfactor=85'));
    });

    test('when the sequencer has inserted enough cells then the cell table '
        'is analyzed in the background, and fewer start nothing', () async {
      RevAnalyze.analyzeAfterRows = 10;
      addTearDown(() => RevAnalyze.analyzeAfterRows = 100000);
      final before = RevAnalyze.started;

      RevAnalyze.inserted(session.serverpod, 'cell', 6);
      final afterFew = RevAnalyze.started;
      RevAnalyze.inserted(session.serverpod, 'cell', 6);
      await RevAnalyze.last;
      RevAnalyze.inserted(session.serverpod, 'sheet', 1000);

      expect(afterFew, before);
      expect(RevAnalyze.started, before + 1);
      final stats = await session.db.unsafeQuery(
        "SELECT last_analyze FROM pg_stat_user_tables WHERE relname = 'cell'",
      );
      expect(stats.first[0], isNotNull);
    });
  });
}
