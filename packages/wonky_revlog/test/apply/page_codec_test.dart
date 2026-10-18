import 'package:test/test.dart';
import 'package:wonky_revlog/apply.dart';
import 'package:wonky_revlog/codec.dart';

import '../support/test_schema.dart';

void main() {
  test(
    'Given a store when its rows are encoded as a page and decoded then they round-trip',
    () {
      final store = MapRowStore();
      applyChanges(testSchema, store, creation(rows: 3));
      final rows = [
        for (final MapEntry(key: t, value: byId) in store.rows.entries)
          for (final row in byId.values) (t, row),
      ];
      final body = RevPageCodec.encode(testSchema, rows);
      List<Object> flat(List<(String, Map<String, Object?>)> l) => [
        for (final (t, r) in l) [t, r],
      ];
      expect(flat(RevPageCodec.decode(testSchema, body)), flat(rows));
    },
  );
}
