/// Block embed models of the Wonky Delta Schema v1
/// (specs/wonky_write/02-document-model.md §1.3).
library;

import 'package:collection/collection.dart';

/// Column alignment of a table embed.
enum CellAlign {
  /// Left aligned (`:---`).
  left('left'),

  /// Centered (`:---:`).
  center('center'),

  /// Right aligned (`---:`).
  right('right');

  const CellAlign(this.value);

  /// JSON value.
  final String value;

  /// Parses a JSON value; `null` for "default" or unknown values.
  static CellAlign? tryParse(Object? value) =>
      CellAlign.values.firstWhereOrNull((a) => a.value == value);
}

/// A block embed: the `insert` value of an embed op is `{<type>: <data>}`.
///
/// Embeds are always on their own line (preceded by `"\n"` or the document
/// start and followed by a plain `"\n"`) and have a stable [id] (UUIDv7).
sealed class WonkyEmbed {
  const WonkyEmbed();

  /// Embed type key (`image`, `divider`, `table`, `grid`, `youtube`).
  String get type;

  /// Stable embed id.
  String get id;

  /// The embed payload (value under [type]).
  Map<String, dynamic> toData();

  /// The full `insert` value (`{type: data}`).
  Map<String, dynamic> toInsert() => {type: toData()};

  /// Known embed type keys.
  static const types = {
    ImageEmbed.typeKey,
    DividerEmbed.typeKey,
    TableEmbed.typeKey,
    GridEmbed.typeKey,
    YouTubeEmbed.typeKey,
  };

  /// Parses an `insert` value. Returns `null` when [insert] is not a valid
  /// embed of a known type.
  static WonkyEmbed? tryParse(Object? insert) {
    if (insert is! Map || insert.length != 1) return null;
    final type = insert.keys.first;
    final data = insert.values.first;
    if (data is! Map) return null;
    return switch (type) {
      ImageEmbed.typeKey => ImageEmbed.tryParse(data),
      DividerEmbed.typeKey => DividerEmbed.tryParse(data),
      TableEmbed.typeKey => TableEmbed.tryParse(data),
      GridEmbed.typeKey => GridEmbed.tryParse(data),
      YouTubeEmbed.typeKey => YouTubeEmbed.tryParse(data),
      _ => null,
    };
  }

  /// The embed type key of an `insert` value, or `null` if it is not a map.
  static String? typeOf(Object? insert) =>
      insert is Map && insert.length == 1 ? '${insert.keys.first}' : null;

  /// The embed id of an `insert` value (valid or not), or `null`.
  static String? idOf(Object? insert) {
    if (insert is! Map || insert.length != 1) return null;
    final data = insert.values.first;
    if (data is! Map) return null;
    final id = data['id'];
    return id is String ? id : null;
  }
}

/// An image: `{"image": {"id", "src", "alt", "title"?}}`.
///
/// `src` is `wonky-file://<fileUuid>` (uploaded), an `https://` (or `http://`)
/// URL, or `import-image://<tempId>` while an import is being post-processed.
final class ImageEmbed extends WonkyEmbed {
  /// Creates an image embed.
  const ImageEmbed({
    required this.id,
    required this.src,
    this.alt = '',
    this.title,
  });

  /// Type key.
  static const typeKey = 'image';

  @override
  String get type => typeKey;

  @override
  final String id;

  /// Image source.
  final String src;

  /// Alternative text (single line).
  final String alt;

  /// Optional title (used as caption).
  final String? title;

  /// Parses the embed payload; `null` when invalid.
  static ImageEmbed? tryParse(Map<dynamic, dynamic> data) {
    final id = data['id'];
    final src = data['src'];
    final alt = data['alt'] ?? '';
    final title = data['title'];
    if (id is! String || id.isEmpty || src is! String || alt is! String) {
      return null;
    }
    if (title != null && title is! String) return null;
    return ImageEmbed(id: id, src: src, alt: alt, title: title as String?);
  }

  /// `wonky-file://` scheme prefix.
  static const wonkyFileScheme = 'wonky-file://';

  /// Temporary import scheme prefix (see 07 §2.2).
  static const importImageScheme = 'import-image://';

  /// The file UUID for a `wonky-file://` source, else `null`.
  String? get fileUuid => src.startsWith(wonkyFileScheme)
      ? src.substring(wonkyFileScheme.length)
      : null;

  @override
  Map<String, dynamic> toData() => {
    'id': id,
    'src': src,
    'alt': alt,
    if (title != null) 'title': title,
  };

  /// Copy with changed fields.
  ImageEmbed copyWith({String? id, String? src, String? alt, String? title}) =>
      ImageEmbed(
        id: id ?? this.id,
        src: src ?? this.src,
        alt: alt ?? this.alt,
        title: title ?? this.title,
      );

  @override
  bool operator ==(Object other) =>
      other is ImageEmbed &&
      other.id == id &&
      other.src == src &&
      other.alt == alt &&
      other.title == title;

  @override
  int get hashCode => Object.hash(id, src, alt, title);

  @override
  String toString() => 'ImageEmbed(${toData()})';
}

/// A horizontal rule: `{"divider": {"id"}}`.
final class DividerEmbed extends WonkyEmbed {
  /// Creates a divider embed.
  const DividerEmbed({required this.id});

  /// Type key.
  static const typeKey = 'divider';

  @override
  String get type => typeKey;

  @override
  final String id;

  /// Parses the embed payload; `null` when invalid.
  static DividerEmbed? tryParse(Map<dynamic, dynamic> data) {
    final id = data['id'];
    if (id is! String || id.isEmpty) return null;
    return DividerEmbed(id: id);
  }

  @override
  Map<String, dynamic> toData() => {'id': id};

  @override
  bool operator ==(Object other) => other is DividerEmbed && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'DividerEmbed($id)';
}

/// A GFM table: `{"table": {"id", "align": [..], "rows": [[cellMarkdown]]}}`.
///
/// Row 0 is the header row; cells are **inline Markdown** strings.
final class TableEmbed extends WonkyEmbed {
  /// Creates a table embed.
  const TableEmbed({required this.id, required this.align, required this.rows});

  /// Type key.
  static const typeKey = 'table';

  @override
  String get type => typeKey;

  @override
  final String id;

  /// Per-column alignment (`null` = default).
  final List<CellAlign?> align;

  /// Rows of inline-Markdown cells; row 0 is the header.
  final List<List<String>> rows;

  /// Number of columns (widest row).
  int get columnCount =>
      rows.fold(align.length, (m, r) => r.length > m ? r.length : m);

  /// Parses the embed payload; `null` when invalid.
  static TableEmbed? tryParse(Map<dynamic, dynamic> data) {
    final id = data['id'];
    final rawRows = data['rows'];
    final rawAlign = data['align'] ?? const <Object?>[];
    if (id is! String || id.isEmpty || rawRows is! List || rawAlign is! List) {
      return null;
    }
    final rows = <List<String>>[];
    for (final row in rawRows) {
      if (row is! List) return null;
      final cells = <String>[];
      for (final cell in row) {
        if (cell is! String) return null;
        cells.add(cell);
      }
      rows.add(cells);
    }
    if (rows.isEmpty) return null;
    final align = <CellAlign?>[];
    for (final a in rawAlign) {
      if (a != null && CellAlign.tryParse(a) == null) return null;
      align.add(CellAlign.tryParse(a));
    }
    return TableEmbed(id: id, align: align, rows: rows);
  }

  @override
  Map<String, dynamic> toData() => {
    'id': id,
    'align': [for (final a in align) a?.value],
    'rows': [
      for (final r in rows) [...r],
    ],
  };

  /// Copy with changed fields.
  TableEmbed copyWith({
    String? id,
    List<CellAlign?>? align,
    List<List<String>>? rows,
  }) => TableEmbed(
    id: id ?? this.id,
    align: align ?? this.align,
    rows: rows ?? this.rows,
  );

  /// A rectangular copy: all rows padded with `""` to [columnCount] and
  /// [align] sized to [columnCount].
  TableEmbed padded() {
    final n = columnCount;
    return TableEmbed(
      id: id,
      align: [for (var i = 0; i < n; i++) i < align.length ? align[i] : null],
      rows: [
        for (final r in rows) [...r, for (var i = r.length; i < n; i++) ''],
      ],
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TableEmbed &&
      other.id == id &&
      const ListEquality<CellAlign?>().equals(other.align, align) &&
      const DeepCollectionEquality().equals(other.rows, rows);

  @override
  int get hashCode => Object.hash(
    id,
    const ListEquality<CellAlign?>().hash(align),
    const DeepCollectionEquality().hash(rows),
  );

  @override
  String toString() => 'TableEmbed(${toData()})';
}

/// The bullet of the items of a [GridEmbed].
enum GridBullets {
  /// A check mark.
  check('check'),

  /// A circle.
  circle('circle'),

  /// No bullet.
  none('none');

  const GridBullets(this.value);

  /// JSON value (and the directive option, `bullets=check`).
  final String value;

  /// Parses a value; unknown values and `null` are [none] (the blog's
  /// default).
  static GridBullets parse(Object? value) =>
      GridBullets.values.firstWhereOrNull((b) => b.value == value) ?? none;
}

/// A Wonky Markdown grid (Write 11 §2.3):
/// `{"grid": {"id", "columns": 1–4, "bullets", "items": [cellMarkdown]}}`.
///
/// Items are stored inline Markdown (like table cells), single line.
final class GridEmbed extends WonkyEmbed {
  /// Creates a grid embed.
  const GridEmbed({
    required this.id,
    this.columns = defaultColumns,
    this.bullets = GridBullets.check,
    required this.items,
  });

  /// Type key.
  static const typeKey = 'grid';

  /// The blog's default column count.
  static const defaultColumns = 3;

  /// Maximum number of items.
  static const maxItems = 100;

  @override
  String get type => typeKey;

  @override
  final String id;

  /// Number of columns, 1–4.
  final int columns;

  /// Item bullets.
  final GridBullets bullets;

  /// Inline-Markdown items (at least one in canonical form).
  final List<String> items;

  /// The canonical column count of a raw value: 1, 2 or 4 as given, 3
  /// otherwise (the blog's rule).
  static int canonicalColumns(Object? value) {
    final n = value is int ? value : int.tryParse('${value ?? ''}');
    return switch (n) {
      1 || 2 || 4 => n!,
      _ => defaultColumns,
    };
  }

  /// Parses the embed payload; `null` when invalid.
  static GridEmbed? tryParse(Map<dynamic, dynamic> data) {
    final id = data['id'];
    final rawItems = data['items'];
    final columns = data['columns'] ?? defaultColumns;
    final bullets = data['bullets'] ?? GridBullets.none.value;
    if (id is! String || id.isEmpty || rawItems is! List) return null;
    if (columns is! int || bullets is! String) return null;
    final items = <String>[];
    for (final item in rawItems) {
      if (item is! String) return null;
      items.add(item);
    }
    return GridEmbed(
      id: id,
      columns: columns,
      bullets: GridBullets.parse(bullets),
      items: items,
    );
  }

  @override
  Map<String, dynamic> toData() => {
    'id': id,
    'columns': columns,
    'bullets': bullets.value,
    'items': [...items],
  };

  /// Copy with changed fields.
  GridEmbed copyWith({
    String? id,
    int? columns,
    GridBullets? bullets,
    List<String>? items,
  }) => GridEmbed(
    id: id ?? this.id,
    columns: columns ?? this.columns,
    bullets: bullets ?? this.bullets,
    items: items ?? this.items,
  );

  @override
  bool operator ==(Object other) =>
      other is GridEmbed &&
      other.id == id &&
      other.columns == columns &&
      other.bullets == bullets &&
      const ListEquality<String>().equals(other.items, items);

  @override
  int get hashCode => Object.hash(
    id,
    columns,
    bullets,
    const ListEquality<String>().hash(items),
  );

  @override
  String toString() => 'GridEmbed(${toData()})';
}

/// A YouTube video (Wonky Markdown, Write 11 §2.3):
/// `{"youtube": {"id", "videoId", "start"?, "title"?}}`.
///
/// [videoId] is the 11-character YouTube id, [start] the start time in
/// seconds, [title] a single-line title (the label of
/// `::youtube[title]{id=… start=…}`).
final class YouTubeEmbed extends WonkyEmbed {
  /// Creates a YouTube embed.
  const YouTubeEmbed({
    required this.id,
    required this.videoId,
    this.start,
    this.title,
  });

  /// Type key.
  static const typeKey = 'youtube';

  /// Longest start time (100 hours).
  static const maxStart = 360000;

  static final _videoId = RegExp(r'^[A-Za-z0-9_-]{11}$');

  @override
  String get type => typeKey;

  @override
  final String id;

  /// The YouTube video id.
  final String videoId;

  /// Start time in seconds.
  final int? start;

  /// Title (single line, no `]`).
  final String? title;

  /// Whether [value] is a YouTube video id.
  static bool isVideoId(String value) => _videoId.hasMatch(value);

  /// Parses the embed payload; `null` when invalid.
  static YouTubeEmbed? tryParse(Map<dynamic, dynamic> data) {
    final id = data['id'];
    final videoId = data['videoId'];
    final start = data['start'];
    final title = data['title'];
    if (id is! String || id.isEmpty || videoId is! String) return null;
    if (!isVideoId(videoId)) return null;
    if (start != null && (start is! int || start < 0 || start > maxStart)) {
      return null;
    }
    if (title != null && title is! String) return null;
    return YouTubeEmbed(
      id: id,
      videoId: videoId,
      start: start as int?,
      title: title as String?,
    );
  }

  /// The video id and start time of a YouTube URL (`watch?v=`, `youtu.be/`,
  /// `/embed/`, `/shorts/`, `/live/`, with `t=`/`start=`) or of a bare video
  /// id; `null` when [input] is neither.
  static ({String videoId, int? start})? parseUrl(String input) {
    final text = input.trim();
    if (isVideoId(text)) return (videoId: text, start: null);
    final uri = Uri.tryParse(text.contains('://') ? text : 'https://$text');
    if (uri == null) return null;
    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^(www|m)\.'), '');
    String? videoId;
    if (host == 'youtu.be') {
      videoId = uri.pathSegments.firstOrNull;
    } else if (host == 'youtube.com' ||
        host == 'music.youtube.com' ||
        host == 'youtube-nocookie.com') {
      final segments = uri.pathSegments;
      if (segments.length == 1 && segments.first == 'watch') {
        videoId = uri.queryParameters['v'];
      } else if (segments.length >= 2 &&
          const {'embed', 'shorts', 'live', 'v'}.contains(segments.first)) {
        videoId = segments[1];
      }
    }
    if (videoId == null || !isVideoId(videoId)) return null;
    final time = uri.queryParameters['t'] ?? uri.queryParameters['start'];
    return (videoId: videoId, start: parseTime(time));
  }

  /// Seconds of a YouTube time (`90`, `90s`, `1m30s`, `1h2m3s`), or `null`.
  static int? parseTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final plain = int.tryParse(value);
    if (plain != null) return plain >= 0 && plain <= maxStart ? plain : null;
    final m = RegExp(r'^(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s)?$').firstMatch(value);
    if (m == null || m.group(0)!.isEmpty) return null;
    final seconds =
        int.parse(m.group(1) ?? '0') * 3600 +
        int.parse(m.group(2) ?? '0') * 60 +
        int.parse(m.group(3) ?? '0');
    return seconds <= maxStart ? seconds : null;
  }

  /// The canonical title of a raw one: single line, `]` as `)` (the
  /// directive label can't hold it), at most 300 characters; empty → `null`.
  static String? canonicalTitle(String? title) {
    if (title == null) return null;
    var t = title
        .replaceAll(RegExp('[\n\r\t\u2028\u2029]'), ' ')
        .replaceAll(']', ')')
        .trim();
    if (t.length > 300) t = t.substring(0, 300).trim();
    return t.isEmpty ? null : t;
  }

  /// The watch page (links, GitHub-style fallback).
  String get watchUrl =>
      'https://www.youtube.com/watch?v=$videoId'
      '${start == null || start == 0 ? '' : '&t=${start}s'}';

  /// The player (HTML export, the blog).
  String get embedUrl =>
      'https://www.youtube.com/embed/$videoId'
      '${start == null || start == 0 ? '' : '?start=$start'}';

  /// The video's thumbnail (16:9 with letterbox bars at `hqdefault`).
  String get thumbnailUrl => 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

  @override
  Map<String, dynamic> toData() => {
    'id': id,
    'videoId': videoId,
    'start': ?start,
    'title': ?title,
  };

  /// Copy with changed fields ([clearStart]/[clearTitle] remove them).
  YouTubeEmbed copyWith({
    String? id,
    String? videoId,
    int? start,
    String? title,
    bool clearStart = false,
    bool clearTitle = false,
  }) => YouTubeEmbed(
    id: id ?? this.id,
    videoId: videoId ?? this.videoId,
    start: clearStart ? null : start ?? this.start,
    title: clearTitle ? null : title ?? this.title,
  );

  @override
  bool operator ==(Object other) =>
      other is YouTubeEmbed &&
      other.id == id &&
      other.videoId == videoId &&
      other.start == start &&
      other.title == title;

  @override
  int get hashCode => Object.hash(id, videoId, start, title);
}
