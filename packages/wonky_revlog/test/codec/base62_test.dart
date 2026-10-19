import 'dart:math';

import 'package:test/test.dart';
import 'package:wonky_revlog/base62.dart';

/// The base-62 UUID codec against a BigInt reference (the limb arithmetic
/// of `Base62Uuid` is a speed-up of the plain conversion).
void main() {
  String reference(List<int> bytes) {
    var v = BigInt.zero;
    for (final b in bytes) {
      v = (v << 8) | BigInt.from(b);
    }
    final out = List.filled(22, '0');
    for (var i = 21; i >= 0; i--) {
      out[i] = base62Digits[(v % BigInt.from(62)).toInt()];
      v ~/= BigInt.from(62);
    }
    return out.join();
  }

  String uuidOf(List<int> b) {
    final hex = [for (final x in b) x.toRadixString(16).padLeft(2, '0')].join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  group('Given random UUIDs (seeded)', () {
    final random = Random(7);
    final samples = [
      List.filled(16, 0),
      List.filled(16, 255),
      for (var i = 0; i < 2000; i++)
        [for (var j = 0; j < 16; j++) random.nextInt(256)],
    ];

    test('when encoded then the ids equal the BigInt conversion', () {
      for (final b in samples) {
        expect(Base62Uuid.encodeBytes(b), reference(b));
        expect(Base62Uuid.encode(uuidOf(b)), reference(b));
        expect(Base62Uuid.encode(uuidOf(b).toUpperCase()), reference(b));
      }
    });

    test('when decoded then the bytes and UUIDs round-trip', () {
      for (final b in samples) {
        final id = reference(b);
        expect(Base62Uuid.decodeBytes(id), b);
        expect(Base62Uuid.decode(id), uuidOf(b));
      }
    });

    test('when an id exceeds 128 bits or a UUID is malformed then it '
        'throws', () {
      expect(
        () => Base62Uuid.decode('7n42DGM5Tflk9n8mt7Fhc8'),
        throwsFormatException,
      );
      expect(
        () => Base62Uuid.encode('0000000-0000-0000-0000-000000000000'),
        throwsFormatException,
      );
      expect(
        () => Base62Uuid.encode('g0000000-0000-0000-0000-000000000000'),
        throwsFormatException,
      );
    });
  });
}
