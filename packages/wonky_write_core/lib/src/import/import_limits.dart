/// Import size limits and import errors (07 §3.1).
library;

import 'package:archive/archive.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart';

import '../delta/delta_utils.dart';

/// Limits on the decompressed content of a ZIP package (DOCX, ODT,
/// Markdown zip) against zip bombs (W-06): [ImportLimits.checkInput] only
/// limits the compressed size.
///
/// [check] runs on the archive's directory, before any part is inflated.
/// The `archive` package never inflates a part past the size its
/// directory declares (it fails instead), and it caches what it inflated,
/// so the declared total bounds what reading the parts can allocate.
final class ArchiveLimits {
  /// Creates custom limits.
  const ArchiveLimits({
    this.maxUnpackedBytes = defaultMaxUnpackedBytes,
    this.maxEntries = defaultMaxEntries,
  });

  /// Default of [maxUnpackedBytes]: 200 MB.
  static const defaultMaxUnpackedBytes = 200 * 1024 * 1024;

  /// Default of [maxEntries].
  static const defaultMaxEntries = 10000;

  /// The limits every importer applies.
  static const standard = ArchiveLimits();

  /// Most bytes the parts may declare in total.
  final int maxUnpackedBytes;

  /// Most entries (files and folders) the package may have.
  final int maxEntries;

  /// Throws [ImportTooLargeException] when [archive] has too many entries
  /// or its files declare more than [maxUnpackedBytes] in total.
  void check(Archive archive) {
    if (archive.files.length > maxEntries) {
      throw ImportTooLargeException(
        ImportLimitKind.archiveEntries,
        actual: archive.files.length,
        limit: maxEntries,
      );
    }
    var total = 0;
    for (final f in archive.files) {
      if (f.isFile) total += f.size;
    }
    if (total > maxUnpackedBytes) {
      throw ImportTooLargeException(
        ImportLimitKind.unpackedBytes,
        actual: total,
        limit: maxUnpackedBytes,
      );
    }
  }
}

/// Size limits applied by [WonkyImporters] (07 §3.1).
///
/// Client imports are limited to [clientMaxInputBytes] of input and
/// [clientMaxResultChars] of resulting document; larger files go to the
/// server, which allows [serverMaxInputBytes] / [serverMaxResultChars]
/// (`write.maxDocumentChars`).
final class ImportLimits {
  /// Creates custom limits.
  const ImportLimits({
    required this.maxInputBytes,
    required this.maxResultChars,
  });

  /// Client input limit: 5 MB.
  static const clientMaxInputBytes = 5 * 1024 * 1024;

  /// Client result limit: 200k characters.
  static const clientMaxResultChars = 200000;

  /// Server input limit: 50 MB.
  static const serverMaxInputBytes = 50 * 1024 * 1024;

  /// Server result limit: 2M characters (`write.maxDocumentChars`).
  static const serverMaxResultChars = 2000000;

  /// Limits for imports running in the apps.
  static const client = ImportLimits(
    maxInputBytes: clientMaxInputBytes,
    maxResultChars: clientMaxResultChars,
  );

  /// Limits for imports running on the server.
  static const server = ImportLimits(
    maxInputBytes: serverMaxInputBytes,
    maxResultChars: serverMaxResultChars,
  );

  /// No limits (tests, tools).
  static const unlimited = ImportLimits(
    maxInputBytes:
        0x1FFFFFFFFFFFFF, // 2^53 - 1: web-safe (1 << n is 0 on the web for n >= 32)
    maxResultChars: 0x1FFFFFFFFFFFFF,
  );

  /// Maximum input size in bytes.
  final int maxInputBytes;

  /// Maximum length of the resulting document delta.
  final int maxResultChars;

  /// Throws [ImportTooLargeException] when [byteLength] exceeds the input
  /// limit.
  void checkInput(int byteLength) {
    if (byteLength > maxInputBytes) {
      throw ImportTooLargeException(
        ImportLimitKind.inputBytes,
        actual: byteLength,
        limit: maxInputBytes,
      );
    }
  }

  /// Throws [ImportTooLargeException] when [document] is longer than the
  /// result limit.
  void checkResult(Delta document) {
    final length = DeltaUtils.documentLength(document);
    if (length > maxResultChars) {
      throw ImportTooLargeException(
        ImportLimitKind.resultChars,
        actual: length,
        limit: maxResultChars,
      );
    }
  }
}

/// Which limit an [ImportTooLargeException] refers to.
enum ImportLimitKind {
  /// The input file is too large.
  inputBytes,

  /// The resulting document is too long.
  resultChars,

  /// The parts of a ZIP package unpack to too many bytes (zip bomb).
  unpackedBytes,

  /// A ZIP package has too many entries.
  archiveEntries,
}

/// The input or the resulting document exceeds the [ImportLimits]
/// (`ImportTooLarge`, 07 §3.1). Clients retry on the server; the server
/// reports it with a message suggesting splitting the file.
final class ImportTooLargeException implements Exception {
  /// Creates the exception.
  const ImportTooLargeException(
    this.kind, {
    required this.actual,
    required this.limit,
  });

  /// Which limit was exceeded.
  final ImportLimitKind kind;

  /// Actual size (bytes or characters).
  final int actual;

  /// The limit (bytes or characters).
  final int limit;

  /// User-facing message.
  String get message => switch (kind) {
    ImportLimitKind.inputBytes =>
      'The file is too large to import ($actual bytes, limit $limit). '
          'Try splitting it into smaller files.',
    ImportLimitKind.resultChars =>
      'The imported document is too long ($actual characters, limit '
          '$limit). Try splitting it into smaller files.',
    ImportLimitKind.unpackedBytes =>
      'The file is too large to import: it unpacks to $actual bytes '
          '(limit $limit). Try splitting it into smaller files.',
    ImportLimitKind.archiveEntries =>
      'The file is too large to import: it contains $actual files '
          '(limit $limit).',
  };

  @override
  String toString() => 'ImportTooLargeException: $message';
}

/// The bytes are clearly not in the expected format (e.g. a DOCX importer
/// given a file that is not a ZIP package). Malformed content in the right
/// format never throws; importers return a best-effort result with warnings.
final class ImportFormatException implements Exception {
  /// Creates the exception.
  const ImportFormatException(this.message);

  /// Description.
  final String message;

  @override
  String toString() => 'ImportFormatException: $message';
}
