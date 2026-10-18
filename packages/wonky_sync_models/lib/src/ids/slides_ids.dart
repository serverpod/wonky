import 'package:uuid/uuid.dart';

import 'package:wonky_revlog/base62.dart';
import 'sheets_ids.dart' show IdGenerator;
import 'uuid5.dart';

/// Deterministic ids of Wonky Slides entities (specs/wonky_slides/02 §2.1),
/// next to `SheetsIds`.
///
/// UUIDv5 over fixed namespace UUIDs. The namespaces and name strings are
/// part of the synced data format: **never change them**. All ids are
/// lower-case dashed UUID strings. UUIDs inside the hashed names (also inside
/// theme source keys and part keys) are normalized to lower case first, so
/// the same entity gets the same id on every replica; other key text is
/// hashed as given (built-in keys are case-sensitive identifiers, Slides 05
/// A-05-2).
abstract final class SlidesIds {
  /// Namespace of `SlideTableCell` ids.
  static const String tableCellNamespace =
      '39c9a227-38ce-4fac-b5e6-19624e40e62d';

  /// Namespace of a slide's placeholder instances (`SlideElement`).
  static const String placeholderInstanceNamespace =
      'df8a317e-da2f-48c3-872a-b413722b7ecb';

  /// Namespace of `DeckTheme` copies of built-in or library themes.
  static const String themeCopyNamespace =
      '4968f861-3f1d-4077-a208-fdd9bf820b6b';

  /// Namespace of the masters, layouts and their elements inside a copied
  /// theme.
  static const String themePartNamespace =
      '5c4bb7e8-b8b6-40d9-9e4d-64f0611c2f80';

  /// Namespace of `ChartLink` ids (max one per chart element).
  static const String chartLinkNamespace =
      '9053ab44-2f66-426b-9c25-40a942138d07';

  static final Uuid5 _cells = Uuid5(tableCellNamespace);
  static final Uuid5 _placeholders = Uuid5(placeholderInstanceNamespace);
  static final Uuid5 _themes = Uuid5(themeCopyNamespace);
  static final Uuid5 _parts = Uuid5(themePartNamespace);
  static final Uuid5 _chartLinks = Uuid5(chartLinkNamespace);

  /// `UUIDv5(ns, "cell:<elementId>:<rowAxisId>:<colAxisId>")`: the
  /// `SlideTableCell` of a table element's row and column axes, so two
  /// offline users typing into the same cell write one row (02 §3.6).
  static String tableCellId(
    String elementId,
    String rowAxisId,
    String colAxisId,
  ) => _cells.of('cell:${_n(elementId)}:${_n(rowAxisId)}:${_n(colAxisId)}');

  /// `UUIDv5(ns, "ph:<slideId>:<layoutPlaceholderId>")`: the slide's
  /// instance of a layout (or master) placeholder element, so applying the
  /// same layout to the same slide on two devices yields one instance.
  static String placeholderInstanceId(
    String slideId,
    String layoutPlaceholderId,
  ) => _placeholders.of('ph:${_n(slideId)}:${_n(layoutPlaceholderId)}');

  /// `UUIDv5(ns, "theme:<deckId>:<sourceKey>")`: a built-in or library theme
  /// copied into deck [deckId] ([sourceKey] from [builtinThemeSourceKey] or
  /// [deckThemeSourceKey]), so two users applying the same theme offline end
  /// up with one copy.
  static String themeCopyId(String deckId, String sourceKey) =>
      _themes.of('theme:${_n(deckId)}:${_key(sourceKey)}');

  /// `UUIDv5(ns, "part:<themeId>:<partKey>")`: a `SlideMaster`, `SlideLayout`
  /// or master/layout `SlideElement` inside a copied theme. [partKey] is the
  /// source row's id or the built-in key (`master:default`,
  /// `layout:titleBody`, `el:titleBody/title`), so the whole copied tree
  /// merges.
  static String themePartId(String themeId, String partKey) =>
      _parts.of('part:${_n(themeId)}:${_key(partKey)}');

  /// `UUIDv5(ns, "chartLink:<elementId>")`: the `ChartLink` of a chart
  /// element (one link row per chart even if two devices link it).
  static String chartLinkId(String elementId) =>
      _chartLinks.of('chartLink:${_n(elementId)}');

  /// The `DeckTheme.sourceKey` of built-in theme [key] at [version]:
  /// `builtin:<key>@<version>`.
  static String builtinThemeSourceKey(String key, int version) =>
      'builtin:$key@$version';

  /// The `DeckTheme.sourceKey` of theme [themeId] of the deck with drive item
  /// [itemUuid]: `deck:<itemUuid>:<themeId>` (lower case).
  static String deckThemeSourceKey(String itemUuid, String themeId) =>
      'deck:${_n(itemUuid)}:${_n(themeId)}';

  /// A fresh `SlideElement.matchKey` (06 §8.2): the 22-character base-62
  /// form of a new id from [ids].
  static String newMatchKey(IdGenerator ids) => Base62Uuid.encode(ids.newId());

  /// [tableCellId] as a [UuidValue].
  static UuidValue tableCellUuid(
    String elementId,
    String rowAxisId,
    String colAxisId,
  ) => UuidValue.fromString(tableCellId(elementId, rowAxisId, colAxisId));

  /// Normalizes a UUID string to the canonical lower-case form.
  static String normalize(String id) => _n(id);

  static String _n(String id) => id.toLowerCase();

  static final RegExp _uuid = RegExp(
    '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    '[0-9a-fA-F]{12}',
  );

  /// [key] with every UUID in it lower-cased (other text unchanged).
  static String _key(String key) =>
      key.replaceAllMapped(_uuid, (m) => m[0]!.toLowerCase());
}
