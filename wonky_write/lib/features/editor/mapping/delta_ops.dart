import 'package:dart_quill_delta/dart_quill_delta.dart';

/// Small Delta helpers used by the editor layer.
abstract final class DeltaOps {
  /// [change].invert([base]) that also works for an empty [base]
  /// (dart_quill_delta 9.x returns an empty inverse in that case).
  static Delta invert(Delta change, Delta base) {
    if (base.isNotEmpty) {
      return change.invert(base);
    }
    var inserted = 0;
    for (final op in change.operations) {
      if (op.isInsert) inserted += op.length!;
    }
    return inserted == 0 ? Delta() : (Delta()..delete(inserted));
  }

  /// Length after minus length before of a change (inserts − deletes).
  static int lengthChange(Delta change) {
    var net = 0;
    for (final op in change.operations) {
      if (op.isInsert) {
        net += op.length!;
      } else if (op.isDelete) {
        net -= op.length!;
      }
    }
    return net;
  }

  /// Total length of a document Delta (inserts only).
  static int documentLength(Delta document) {
    var length = 0;
    for (final op in document.operations) {
      length += op.length!;
    }
    return length;
  }

  /// The length of the document a change applies to (retains + deletes).
  static int baseLength(Delta change) {
    var length = 0;
    for (final op in change.operations) {
      if (!op.isInsert) length += op.length!;
    }
    return length;
  }

  /// A change that inserts [fragment] at [offset].
  static Delta insertAt(int offset, Delta fragment) {
    final delta = Delta()..retain(offset);
    for (final op in fragment.operations) {
      delta.push(op);
    }
    return delta;
  }

  /// A change that formats `[start, start + length)` with [attributes].
  static Delta format(int start, int length, Map<String, dynamic> attributes) =>
      Delta()
        ..retain(start)
        ..retain(length, attributes);

  /// A change that deletes `[start, start + length)`.
  static Delta deleteRange(int start, int length) => Delta()
    ..retain(start)
    ..delete(length);

  /// Shifts [change] by [offset] (prepends a retain).
  static Delta shift(Delta change, int offset) {
    if (offset == 0) return change;
    final delta = Delta()..retain(offset);
    for (final op in change.operations) {
      delta.push(op);
    }
    delta.trim();
    return delta;
  }

  /// Plain text of a document Delta; embeds count as one U+FFFC character.
  static String plainText(Delta document) {
    final buffer = StringBuffer();
    for (final op in document.operations) {
      final data = op.data;
      buffer.write(data is String ? data : '￼');
    }
    return buffer.toString();
  }
}
