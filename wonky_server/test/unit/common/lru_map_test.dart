import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/lru_map.dart';

/// `LruMap` (code-quality theme T5): per-instance maps stay bounded.
void main() {
  group('Given an LRU map of three entries', () {
    late LruMap<String, int> map;
    setUp(() {
      map = LruMap(3)
        ..put('a', 1)
        ..put('b', 2)
        ..put('c', 3);
    });

    test('when a fourth entry is put then the oldest is evicted', () {
      map.put('d', 4);

      expect(map.keys, ['b', 'c', 'd']);
      expect(map.get('a'), isNull);
    });

    test('when an entry is read before the put then it is kept', () {
      expect(map.get('a'), 1);

      map.put('d', 4);

      expect(map.keys, ['c', 'a', 'd']);
    });

    test('when an entry is peeked then its order does not change', () {
      expect(map.peek('a'), 1);

      map.put('d', 4);

      expect(map.containsKey('a'), isFalse);
    });

    test('when entries are removed by a test then the rest stay', () {
      map.removeWhere((_, v) => v.isOdd);

      expect(map.keys, ['b']);
      expect(map.length, 1);
    });
  });
}
