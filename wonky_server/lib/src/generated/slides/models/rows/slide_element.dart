/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_null_comparison

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _ida;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:wonky_server/src/generated/protocol.dart' as _il4umwa0;
import '../../../platform/revlog/models/rev_file.dart' as _imcki4bb;
import '../../../slides/models/rows/enums/placeholder_type.dart' as _ie1g0ftm;
import '../../../slides/models/rows/enums/slide_element_kind.dart' as _i21f8som;
import '../../../slides/models/rows/slide.dart' as _iet418te;
import '../../../slides/models/rows/slide_element.dart' as _ip9zwo22;
import '../../../slides/models/rows/slide_layout.dart' as _it7mv5qw;
import '../../../slides/models/rows/slide_master.dart' as _iqzg1yqp;

/// Any object on a slide, layout or master (Slides 02 §3.5). Exactly one
/// owner FK (slide, layout, master: optional relations) is set; a child of
/// an element group has the owner of its group.
abstract class SlideElement
    implements _is.TableRow<_is.UuidValue>, _is.ProtocolSerialization {
  SlideElement._({
    _is.UuidValue? id,
    required this.fileId,
    this.file,
    int? revision,
    this.slideId,
    this.slide,
    this.layoutId,
    this.layout,
    this.masterId,
    this.master,
    this.parentId,
    this.parent,
    required this.kind,
    this.name,
    this.x,
    this.y,
    this.width,
    this.height,
    this.rotation,
    bool? flipH,
    bool? flipV,
    required this.zKey,
    this.readingKey,
    bool? locked,
    bool? hidden,
    this.placeholderType,
    this.placeholderOf,
    required this.matchKey,
    this.text,
    this.textStyleJson,
    this.fillJson,
    this.strokeJson,
    this.effectsJson,
    this.opacity,
    this.dataJson,
    this.linkJson,
    this.altText,
    bool? decorative,
    DateTime? createdAt,
  }) : id = id ?? const _is.Uuid().v7obj(),
       revision = revision ?? 0,
       flipH = flipH ?? false,
       flipV = flipV ?? false,
       locked = locked ?? false,
       hidden = hidden ?? false,
       decorative = decorative ?? false,
       createdAt = createdAt ?? DateTime.now();

  factory SlideElement({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    _is.UuidValue? slideId,
    _iet418te.Slide? slide,
    _is.UuidValue? layoutId,
    _it7mv5qw.SlideLayout? layout,
    _is.UuidValue? masterId,
    _iqzg1yqp.SlideMaster? master,
    _is.UuidValue? parentId,
    _ip9zwo22.SlideElement? parent,
    required _i21f8som.SlideElementKind kind,
    String? name,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    bool? flipH,
    bool? flipV,
    required String zKey,
    String? readingKey,
    bool? locked,
    bool? hidden,
    _ie1g0ftm.PlaceholderType? placeholderType,
    _is.UuidValue? placeholderOf,
    required String matchKey,
    String? text,
    String? textStyleJson,
    String? fillJson,
    String? strokeJson,
    String? effectsJson,
    double? opacity,
    String? dataJson,
    String? linkJson,
    String? altText,
    bool? decorative,
    DateTime? createdAt,
  }) = _SlideElementImpl;

  factory SlideElement.fromJson(Map<String, dynamic> jsonSerialization) {
    return SlideElement(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      fileId: jsonSerialization['fileId'] as int,
      file: jsonSerialization['file'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_imcki4bb.RevFile>(
              jsonSerialization['file'],
            ),
      revision: jsonSerialization['revision'] as int?,
      slideId: jsonSerialization['slideId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['slideId']),
      slide: jsonSerialization['slide'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_iet418te.Slide>(
              jsonSerialization['slide'],
            ),
      layoutId: jsonSerialization['layoutId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['layoutId']),
      layout: jsonSerialization['layout'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_it7mv5qw.SlideLayout>(
              jsonSerialization['layout'],
            ),
      masterId: jsonSerialization['masterId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['masterId']),
      master: jsonSerialization['master'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_iqzg1yqp.SlideMaster>(
              jsonSerialization['master'],
            ),
      parentId: jsonSerialization['parentId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['parentId']),
      parent: jsonSerialization['parent'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_ip9zwo22.SlideElement>(
              jsonSerialization['parent'],
            ),
      kind: _i21f8som.SlideElementKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      name: jsonSerialization['name'] as String?,
      x: (jsonSerialization['x'] as num?)?.toDouble(),
      y: (jsonSerialization['y'] as num?)?.toDouble(),
      width: (jsonSerialization['width'] as num?)?.toDouble(),
      height: (jsonSerialization['height'] as num?)?.toDouble(),
      rotation: (jsonSerialization['rotation'] as num?)?.toDouble(),
      flipH: jsonSerialization['flipH'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['flipH']),
      flipV: jsonSerialization['flipV'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['flipV']),
      zKey: jsonSerialization['zKey'] as String,
      readingKey: jsonSerialization['readingKey'] as String?,
      locked: jsonSerialization['locked'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['locked']),
      hidden: jsonSerialization['hidden'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['hidden']),
      placeholderType: jsonSerialization['placeholderType'] == null
          ? null
          : _ie1g0ftm.PlaceholderType.fromJson(
              (jsonSerialization['placeholderType'] as String),
            ),
      placeholderOf: jsonSerialization['placeholderOf'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['placeholderOf'],
            ),
      matchKey: jsonSerialization['matchKey'] as String,
      text: jsonSerialization['text'] as String?,
      textStyleJson: jsonSerialization['textStyleJson'] as String?,
      fillJson: jsonSerialization['fillJson'] as String?,
      strokeJson: jsonSerialization['strokeJson'] as String?,
      effectsJson: jsonSerialization['effectsJson'] as String?,
      opacity: (jsonSerialization['opacity'] as num?)?.toDouble(),
      dataJson: jsonSerialization['dataJson'] as String?,
      linkJson: jsonSerialization['linkJson'] as String?,
      altText: jsonSerialization['altText'] as String?,
      decorative: jsonSerialization['decorative'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['decorative']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = SlideElementTable();

  static const db = SlideElementRepository._();

  @override
  _is.UuidValue id;

  int fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFile? file;

  /// The revision that last wrote the row.
  int revision;

  _is.UuidValue? slideId;

  _iet418te.Slide? slide;

  _is.UuidValue? layoutId;

  _it7mv5qw.SlideLayout? layout;

  _is.UuidValue? masterId;

  _iqzg1yqp.SlideMaster? master;

  _is.UuidValue? parentId;

  /// Element group (kind group) this element belongs to. Deleting a group
  /// deletes its children.
  _ip9zwo22.SlideElement? parent;

  _i21f8som.SlideElementKind kind;

  /// Layers panel / animation pane label; null = generated ("Shape 3").
  String? name;

  /// Frame (02 §2.2) in su; x/y top-left of the unrotated box. Nullable only
  /// on placeholder instances (null = inherit). Coupled columns (P4).
  double? x;

  double? y;

  double? width;

  double? height;

  /// Degrees clockwise about the center; null = 0 (placeholders: inherit).
  double? rotation;

  bool flipH;

  bool flipV;

  /// Stacking order among siblings (same owner and parent).
  String zKey;

  /// Reading order override (03 §17); null = automatic.
  String? readingKey;

  /// Not selectable by click/marquee, can't move (03 §8.2).
  bool locked;

  /// Not drawn (still in the Layers panel); hidden in present/PDF.
  bool hidden;

  /// On layouts/masters: defines a placeholder; on slides: an instance.
  _ie1g0ftm.PlaceholderType? placeholderType;

  /// Instance -> the layout (or master) placeholder it inherits from (plain UUID).
  _is.UuidValue? placeholderOf;

  /// Magic Move key (06 §8.2): 22-character key generated on create.
  String matchKey;

  /// Rich text Delta (02 §4) of text/shape/placeholder; null for code.
  String? text;

  /// Box-level text properties (02 §5.1).
  String? textStyleJson;

  /// Fill (02 §5.2); null = inherit/none per kind.
  String? fillJson;

  /// Stroke (02 §5.3).
  String? strokeJson;

  /// Shadow, glow, blur, reflection (02 §5.4).
  String? effectsJson;

  /// 0..1; null = 1.
  double? opacity;

  /// Kind-specific payload (02 §6), always with "v".
  String? dataJson;

  /// Click action when presenting: {url} | {slideId} | {action} (03 §6.9).
  String? linkJson;

  String? altText;

  /// Excluded from alt-text checks and screen readers.
  bool decorative;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue> get table => t;

  /// Returns a shallow copy of this [SlideElement]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SlideElement copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedSlideElement$file(),
    int? revision,
    _is.UuidValue? slideId = const _is.$UndefinedUuidValue(),
    _iet418te.Slide? slide = const _UndefinedSlideElement$slide(),
    _is.UuidValue? layoutId = const _is.$UndefinedUuidValue(),
    _it7mv5qw.SlideLayout? layout = const _UndefinedSlideElement$layout(),
    _is.UuidValue? masterId = const _is.$UndefinedUuidValue(),
    _iqzg1yqp.SlideMaster? master = const _UndefinedSlideElement$master(),
    _is.UuidValue? parentId = const _is.$UndefinedUuidValue(),
    _ip9zwo22.SlideElement? parent = const _UndefinedSlideElement$parent(),
    _i21f8som.SlideElementKind? kind,
    String? name,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    bool? flipH,
    bool? flipV,
    String? zKey,
    String? readingKey,
    bool? locked,
    bool? hidden,
    _ie1g0ftm.PlaceholderType? placeholderType,
    _is.UuidValue? placeholderOf = const _is.$UndefinedUuidValue(),
    String? matchKey,
    String? text,
    String? textStyleJson,
    String? fillJson,
    String? strokeJson,
    String? effectsJson,
    double? opacity,
    String? dataJson,
    String? linkJson,
    String? altText,
    bool? decorative,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SlideElement',
      'id': id.toJson(),
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'revision': revision,
      if (slideId != null) 'slideId': slideId?.toJson(),
      if (slide != null) 'slide': slide?.toJson(),
      if (layoutId != null) 'layoutId': layoutId?.toJson(),
      if (layout != null) 'layout': layout?.toJson(),
      if (masterId != null) 'masterId': masterId?.toJson(),
      if (master != null) 'master': master?.toJson(),
      if (parentId != null) 'parentId': parentId?.toJson(),
      if (parent != null) 'parent': parent?.toJson(),
      'kind': kind.toJson(),
      if (name != null) 'name': name,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (rotation != null) 'rotation': rotation,
      'flipH': flipH,
      'flipV': flipV,
      'zKey': zKey,
      if (readingKey != null) 'readingKey': readingKey,
      'locked': locked,
      'hidden': hidden,
      if (placeholderType != null) 'placeholderType': placeholderType?.toJson(),
      if (placeholderOf != null) 'placeholderOf': placeholderOf?.toJson(),
      'matchKey': matchKey,
      if (text != null) 'text': text,
      if (textStyleJson != null) 'textStyleJson': textStyleJson,
      if (fillJson != null) 'fillJson': fillJson,
      if (strokeJson != null) 'strokeJson': strokeJson,
      if (effectsJson != null) 'effectsJson': effectsJson,
      if (opacity != null) 'opacity': opacity,
      if (dataJson != null) 'dataJson': dataJson,
      if (linkJson != null) 'linkJson': linkJson,
      if (altText != null) 'altText': altText,
      'decorative': decorative,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static SlideElementInclude include({
    _imcki4bb.RevFileInclude? file,
    _iet418te.SlideInclude? slide,
    _it7mv5qw.SlideLayoutInclude? layout,
    _iqzg1yqp.SlideMasterInclude? master,
    _ip9zwo22.SlideElementInclude? parent,
  }) {
    return SlideElementInclude._(
      file: file,
      slide: slide,
      layout: layout,
      master: master,
      parent: parent,
    );
  }

  static SlideElementIncludeList includeList({
    _is.WhereExpressionBuilder<SlideElementTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SlideElementTable>? orderBy,
    _is.OrderByListBuilder<SlideElementTable>? orderByList,
    SlideElementInclude? include,
  }) {
    return SlideElementIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SlideElement.t),
      orderByList: orderByList?.call(SlideElement.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedSlideElement$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedSlideElement$file();
}

class _UndefinedSlideElement$slide extends _is.UndefinedSentinel
    implements _iet418te.Slide {
  const _UndefinedSlideElement$slide();
}

class _UndefinedSlideElement$layout extends _is.UndefinedSentinel
    implements _it7mv5qw.SlideLayout {
  const _UndefinedSlideElement$layout();
}

class _UndefinedSlideElement$master extends _is.UndefinedSentinel
    implements _iqzg1yqp.SlideMaster {
  const _UndefinedSlideElement$master();
}

class _UndefinedSlideElement$parent extends _is.UndefinedSentinel
    implements _ip9zwo22.SlideElement {
  const _UndefinedSlideElement$parent();
}

class _SlideElementImpl extends SlideElement {
  _SlideElementImpl({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    _is.UuidValue? slideId,
    _iet418te.Slide? slide,
    _is.UuidValue? layoutId,
    _it7mv5qw.SlideLayout? layout,
    _is.UuidValue? masterId,
    _iqzg1yqp.SlideMaster? master,
    _is.UuidValue? parentId,
    _ip9zwo22.SlideElement? parent,
    required _i21f8som.SlideElementKind kind,
    String? name,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    bool? flipH,
    bool? flipV,
    required String zKey,
    String? readingKey,
    bool? locked,
    bool? hidden,
    _ie1g0ftm.PlaceholderType? placeholderType,
    _is.UuidValue? placeholderOf,
    required String matchKey,
    String? text,
    String? textStyleJson,
    String? fillJson,
    String? strokeJson,
    String? effectsJson,
    double? opacity,
    String? dataJson,
    String? linkJson,
    String? altText,
    bool? decorative,
    DateTime? createdAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         revision: revision,
         slideId: slideId,
         slide: slide,
         layoutId: layoutId,
         layout: layout,
         masterId: masterId,
         master: master,
         parentId: parentId,
         parent: parent,
         kind: kind,
         name: name,
         x: x,
         y: y,
         width: width,
         height: height,
         rotation: rotation,
         flipH: flipH,
         flipV: flipV,
         zKey: zKey,
         readingKey: readingKey,
         locked: locked,
         hidden: hidden,
         placeholderType: placeholderType,
         placeholderOf: placeholderOf,
         matchKey: matchKey,
         text: text,
         textStyleJson: textStyleJson,
         fillJson: fillJson,
         strokeJson: strokeJson,
         effectsJson: effectsJson,
         opacity: opacity,
         dataJson: dataJson,
         linkJson: linkJson,
         altText: altText,
         decorative: decorative,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [SlideElement]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SlideElement copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedSlideElement$file(),
    int? revision,
    _is.UuidValue? slideId = const _is.$UndefinedUuidValue(),
    _iet418te.Slide? slide = const _UndefinedSlideElement$slide(),
    _is.UuidValue? layoutId = const _is.$UndefinedUuidValue(),
    _it7mv5qw.SlideLayout? layout = const _UndefinedSlideElement$layout(),
    _is.UuidValue? masterId = const _is.$UndefinedUuidValue(),
    _iqzg1yqp.SlideMaster? master = const _UndefinedSlideElement$master(),
    _is.UuidValue? parentId = const _is.$UndefinedUuidValue(),
    _ip9zwo22.SlideElement? parent = const _UndefinedSlideElement$parent(),
    _i21f8som.SlideElementKind? kind,
    Object? name = _Undefined,
    Object? x = _Undefined,
    Object? y = _Undefined,
    Object? width = _Undefined,
    Object? height = _Undefined,
    Object? rotation = _Undefined,
    bool? flipH,
    bool? flipV,
    String? zKey,
    Object? readingKey = _Undefined,
    bool? locked,
    bool? hidden,
    Object? placeholderType = _Undefined,
    _is.UuidValue? placeholderOf = const _is.$UndefinedUuidValue(),
    String? matchKey,
    Object? text = _Undefined,
    Object? textStyleJson = _Undefined,
    Object? fillJson = _Undefined,
    Object? strokeJson = _Undefined,
    Object? effectsJson = _Undefined,
    Object? opacity = _Undefined,
    Object? dataJson = _Undefined,
    Object? linkJson = _Undefined,
    Object? altText = _Undefined,
    bool? decorative,
    DateTime? createdAt,
  }) {
    return SlideElement(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      revision: revision ?? this.revision,
      slideId: slideId is _is.UndefinedSentinel ? this.slideId : slideId,
      slide: slide is _is.UndefinedSentinel ? this.slide?.copyWith() : slide,
      layoutId: layoutId is _is.UndefinedSentinel ? this.layoutId : layoutId,
      layout: layout is _is.UndefinedSentinel
          ? this.layout?.copyWith()
          : layout,
      masterId: masterId is _is.UndefinedSentinel ? this.masterId : masterId,
      master: master is _is.UndefinedSentinel
          ? this.master?.copyWith()
          : master,
      parentId: parentId is _is.UndefinedSentinel ? this.parentId : parentId,
      parent: parent is _is.UndefinedSentinel
          ? this.parent?.copyWith()
          : parent,
      kind: kind ?? this.kind,
      name: name is String? ? name : this.name,
      x: x is double? ? x : this.x,
      y: y is double? ? y : this.y,
      width: width is double? ? width : this.width,
      height: height is double? ? height : this.height,
      rotation: rotation is double? ? rotation : this.rotation,
      flipH: flipH ?? this.flipH,
      flipV: flipV ?? this.flipV,
      zKey: zKey ?? this.zKey,
      readingKey: readingKey is String? ? readingKey : this.readingKey,
      locked: locked ?? this.locked,
      hidden: hidden ?? this.hidden,
      placeholderType: placeholderType is _ie1g0ftm.PlaceholderType?
          ? placeholderType
          : this.placeholderType,
      placeholderOf: placeholderOf is _is.UndefinedSentinel
          ? this.placeholderOf
          : placeholderOf,
      matchKey: matchKey ?? this.matchKey,
      text: text is String? ? text : this.text,
      textStyleJson: textStyleJson is String?
          ? textStyleJson
          : this.textStyleJson,
      fillJson: fillJson is String? ? fillJson : this.fillJson,
      strokeJson: strokeJson is String? ? strokeJson : this.strokeJson,
      effectsJson: effectsJson is String? ? effectsJson : this.effectsJson,
      opacity: opacity is double? ? opacity : this.opacity,
      dataJson: dataJson is String? ? dataJson : this.dataJson,
      linkJson: linkJson is String? ? linkJson : this.linkJson,
      altText: altText is String? ? altText : this.altText,
      decorative: decorative ?? this.decorative,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class SlideElementUpdateTable extends _is.UpdateTable<SlideElementTable> {
  SlideElementUpdateTable(super.table);

  _is.ColumnValue<int, int> fileId(int value) => _is.ColumnValue(
    table.fileId,
    value,
  );

  _is.ColumnValue<int, int> revision(int value) => _is.ColumnValue(
    table.revision,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> slideId(_is.UuidValue? value) =>
      _is.ColumnValue(
        table.slideId,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> layoutId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.layoutId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> masterId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.masterId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> parentId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.parentId,
    value,
  );

  _is.ColumnValue<_i21f8som.SlideElementKind, _i21f8som.SlideElementKind> kind(
    _i21f8som.SlideElementKind value,
  ) => _is.ColumnValue(
    table.kind,
    value,
  );

  _is.ColumnValue<String, String> name(String? value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<double, double> x(double? value) => _is.ColumnValue(
    table.x,
    value,
  );

  _is.ColumnValue<double, double> y(double? value) => _is.ColumnValue(
    table.y,
    value,
  );

  _is.ColumnValue<double, double> width(double? value) => _is.ColumnValue(
    table.width,
    value,
  );

  _is.ColumnValue<double, double> height(double? value) => _is.ColumnValue(
    table.height,
    value,
  );

  _is.ColumnValue<double, double> rotation(double? value) => _is.ColumnValue(
    table.rotation,
    value,
  );

  _is.ColumnValue<bool, bool> flipH(bool value) => _is.ColumnValue(
    table.flipH,
    value,
  );

  _is.ColumnValue<bool, bool> flipV(bool value) => _is.ColumnValue(
    table.flipV,
    value,
  );

  _is.ColumnValue<String, String> zKey(String value) => _is.ColumnValue(
    table.zKey,
    value,
  );

  _is.ColumnValue<String, String> readingKey(String? value) => _is.ColumnValue(
    table.readingKey,
    value,
  );

  _is.ColumnValue<bool, bool> locked(bool value) => _is.ColumnValue(
    table.locked,
    value,
  );

  _is.ColumnValue<bool, bool> hidden(bool value) => _is.ColumnValue(
    table.hidden,
    value,
  );

  _is.ColumnValue<_ie1g0ftm.PlaceholderType, _ie1g0ftm.PlaceholderType>
  placeholderType(_ie1g0ftm.PlaceholderType? value) => _is.ColumnValue(
    table.placeholderType,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> placeholderOf(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.placeholderOf,
    value,
  );

  _is.ColumnValue<String, String> matchKey(String value) => _is.ColumnValue(
    table.matchKey,
    value,
  );

  _is.ColumnValue<String, String> text(String? value) => _is.ColumnValue(
    table.text,
    value,
  );

  _is.ColumnValue<String, String> textStyleJson(String? value) =>
      _is.ColumnValue(
        table.textStyleJson,
        value,
      );

  _is.ColumnValue<String, String> fillJson(String? value) => _is.ColumnValue(
    table.fillJson,
    value,
  );

  _is.ColumnValue<String, String> strokeJson(String? value) => _is.ColumnValue(
    table.strokeJson,
    value,
  );

  _is.ColumnValue<String, String> effectsJson(String? value) => _is.ColumnValue(
    table.effectsJson,
    value,
  );

  _is.ColumnValue<double, double> opacity(double? value) => _is.ColumnValue(
    table.opacity,
    value,
  );

  _is.ColumnValue<String, String> dataJson(String? value) => _is.ColumnValue(
    table.dataJson,
    value,
  );

  _is.ColumnValue<String, String> linkJson(String? value) => _is.ColumnValue(
    table.linkJson,
    value,
  );

  _is.ColumnValue<String, String> altText(String? value) => _is.ColumnValue(
    table.altText,
    value,
  );

  _is.ColumnValue<bool, bool> decorative(bool value) => _is.ColumnValue(
    table.decorative,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class SlideElementTable extends _is.Table<_is.UuidValue> {
  SlideElementTable({super.tableRelation}) : super(tableName: 'slide_element') {
    updateTable = SlideElementUpdateTable(this);
    fileId = _is.ColumnInt(
      'fileId',
      this,
    );
    revision = _is.ColumnInt(
      'revision',
      this,
      hasDefault: true,
    );
    slideId = _is.ColumnUuid(
      'slideId',
      this,
    );
    layoutId = _is.ColumnUuid(
      'layoutId',
      this,
    );
    masterId = _is.ColumnUuid(
      'masterId',
      this,
    );
    parentId = _is.ColumnUuid(
      'parentId',
      this,
    );
    kind = _is.ColumnEnum(
      'kind',
      this,
      _is.EnumSerialization.byName,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    x = _is.ColumnDouble(
      'x',
      this,
    );
    y = _is.ColumnDouble(
      'y',
      this,
    );
    width = _is.ColumnDouble(
      'width',
      this,
    );
    height = _is.ColumnDouble(
      'height',
      this,
    );
    rotation = _is.ColumnDouble(
      'rotation',
      this,
    );
    flipH = _is.ColumnBool(
      'flipH',
      this,
      hasDefault: true,
    );
    flipV = _is.ColumnBool(
      'flipV',
      this,
      hasDefault: true,
    );
    zKey = _is.ColumnString(
      'zKey',
      this,
    );
    readingKey = _is.ColumnString(
      'readingKey',
      this,
    );
    locked = _is.ColumnBool(
      'locked',
      this,
      hasDefault: true,
    );
    hidden = _is.ColumnBool(
      'hidden',
      this,
      hasDefault: true,
    );
    placeholderType = _is.ColumnEnum(
      'placeholderType',
      this,
      _is.EnumSerialization.byName,
    );
    placeholderOf = _is.ColumnUuid(
      'placeholderOf',
      this,
    );
    matchKey = _is.ColumnString(
      'matchKey',
      this,
    );
    text = _is.ColumnString(
      'text',
      this,
    );
    textStyleJson = _is.ColumnString(
      'textStyleJson',
      this,
    );
    fillJson = _is.ColumnString(
      'fillJson',
      this,
    );
    strokeJson = _is.ColumnString(
      'strokeJson',
      this,
    );
    effectsJson = _is.ColumnString(
      'effectsJson',
      this,
    );
    opacity = _is.ColumnDouble(
      'opacity',
      this,
    );
    dataJson = _is.ColumnString(
      'dataJson',
      this,
    );
    linkJson = _is.ColumnString(
      'linkJson',
      this,
    );
    altText = _is.ColumnString(
      'altText',
      this,
    );
    decorative = _is.ColumnBool(
      'decorative',
      this,
      hasDefault: true,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final SlideElementUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFileTable? _file;

  /// The revision that last wrote the row.
  late final _is.ColumnInt revision;

  late final _is.ColumnUuid slideId;

  _iet418te.SlideTable? _slide;

  late final _is.ColumnUuid layoutId;

  _it7mv5qw.SlideLayoutTable? _layout;

  late final _is.ColumnUuid masterId;

  _iqzg1yqp.SlideMasterTable? _master;

  late final _is.ColumnUuid parentId;

  /// Element group (kind group) this element belongs to. Deleting a group
  /// deletes its children.
  _ip9zwo22.SlideElementTable? _parent;

  late final _is.ColumnEnum<_i21f8som.SlideElementKind> kind;

  /// Layers panel / animation pane label; null = generated ("Shape 3").
  late final _is.ColumnString name;

  /// Frame (02 §2.2) in su; x/y top-left of the unrotated box. Nullable only
  /// on placeholder instances (null = inherit). Coupled columns (P4).
  late final _is.ColumnDouble x;

  late final _is.ColumnDouble y;

  late final _is.ColumnDouble width;

  late final _is.ColumnDouble height;

  /// Degrees clockwise about the center; null = 0 (placeholders: inherit).
  late final _is.ColumnDouble rotation;

  late final _is.ColumnBool flipH;

  late final _is.ColumnBool flipV;

  /// Stacking order among siblings (same owner and parent).
  late final _is.ColumnString zKey;

  /// Reading order override (03 §17); null = automatic.
  late final _is.ColumnString readingKey;

  /// Not selectable by click/marquee, can't move (03 §8.2).
  late final _is.ColumnBool locked;

  /// Not drawn (still in the Layers panel); hidden in present/PDF.
  late final _is.ColumnBool hidden;

  /// On layouts/masters: defines a placeholder; on slides: an instance.
  late final _is.ColumnEnum<_ie1g0ftm.PlaceholderType> placeholderType;

  /// Instance -> the layout (or master) placeholder it inherits from (plain UUID).
  late final _is.ColumnUuid placeholderOf;

  /// Magic Move key (06 §8.2): 22-character key generated on create.
  late final _is.ColumnString matchKey;

  /// Rich text Delta (02 §4) of text/shape/placeholder; null for code.
  late final _is.ColumnString text;

  /// Box-level text properties (02 §5.1).
  late final _is.ColumnString textStyleJson;

  /// Fill (02 §5.2); null = inherit/none per kind.
  late final _is.ColumnString fillJson;

  /// Stroke (02 §5.3).
  late final _is.ColumnString strokeJson;

  /// Shadow, glow, blur, reflection (02 §5.4).
  late final _is.ColumnString effectsJson;

  /// 0..1; null = 1.
  late final _is.ColumnDouble opacity;

  /// Kind-specific payload (02 §6), always with "v".
  late final _is.ColumnString dataJson;

  /// Click action when presenting: {url} | {slideId} | {action} (03 §6.9).
  late final _is.ColumnString linkJson;

  late final _is.ColumnString altText;

  /// Excluded from alt-text checks and screen readers.
  late final _is.ColumnBool decorative;

  late final _is.ColumnDateTime createdAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: SlideElement.t.fileId,
      foreignField: _imcki4bb.RevFile.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _imcki4bb.RevFileTable(tableRelation: foreignTableRelation),
    );
    return _file!;
  }

  _iet418te.SlideTable get slide {
    if (_slide != null) return _slide!;
    _slide = _is.createRelationTable(
      relationFieldName: 'slide',
      field: SlideElement.t.slideId,
      foreignField: _iet418te.Slide.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iet418te.SlideTable(tableRelation: foreignTableRelation),
    );
    return _slide!;
  }

  _it7mv5qw.SlideLayoutTable get layout {
    if (_layout != null) return _layout!;
    _layout = _is.createRelationTable(
      relationFieldName: 'layout',
      field: SlideElement.t.layoutId,
      foreignField: _it7mv5qw.SlideLayout.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _it7mv5qw.SlideLayoutTable(tableRelation: foreignTableRelation),
    );
    return _layout!;
  }

  _iqzg1yqp.SlideMasterTable get master {
    if (_master != null) return _master!;
    _master = _is.createRelationTable(
      relationFieldName: 'master',
      field: SlideElement.t.masterId,
      foreignField: _iqzg1yqp.SlideMaster.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iqzg1yqp.SlideMasterTable(tableRelation: foreignTableRelation),
    );
    return _master!;
  }

  _ip9zwo22.SlideElementTable get parent {
    if (_parent != null) return _parent!;
    _parent = _is.createRelationTable(
      relationFieldName: 'parent',
      field: SlideElement.t.parentId,
      foreignField: _ip9zwo22.SlideElement.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _ip9zwo22.SlideElementTable(tableRelation: foreignTableRelation),
    );
    return _parent!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    fileId,
    revision,
    slideId,
    layoutId,
    masterId,
    parentId,
    kind,
    name,
    x,
    y,
    width,
    height,
    rotation,
    flipH,
    flipV,
    zKey,
    readingKey,
    locked,
    hidden,
    placeholderType,
    placeholderOf,
    matchKey,
    text,
    textStyleJson,
    fillJson,
    strokeJson,
    effectsJson,
    opacity,
    dataJson,
    linkJson,
    altText,
    decorative,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'file') {
      return file;
    }
    if (relationField == 'slide') {
      return slide;
    }
    if (relationField == 'layout') {
      return layout;
    }
    if (relationField == 'master') {
      return master;
    }
    if (relationField == 'parent') {
      return parent;
    }
    return null;
  }
}

class SlideElementInclude extends _is.IncludeObject {
  SlideElementInclude._({
    _imcki4bb.RevFileInclude? file,
    _iet418te.SlideInclude? slide,
    _it7mv5qw.SlideLayoutInclude? layout,
    _iqzg1yqp.SlideMasterInclude? master,
    _ip9zwo22.SlideElementInclude? parent,
  }) {
    _file = file;
    _slide = slide;
    _layout = layout;
    _master = master;
    _parent = parent;
  }

  _imcki4bb.RevFileInclude? _file;

  _iet418te.SlideInclude? _slide;

  _it7mv5qw.SlideLayoutInclude? _layout;

  _iqzg1yqp.SlideMasterInclude? _master;

  _ip9zwo22.SlideElementInclude? _parent;

  @override
  Map<String, _is.Include?> get includes => {
    'file': _file,
    'slide': _slide,
    'layout': _layout,
    'master': _master,
    'parent': _parent,
  };

  @override
  _is.Table<_is.UuidValue> get table => SlideElement.t;
}

class SlideElementIncludeList extends _is.IncludeList {
  SlideElementIncludeList._({
    _is.WhereExpressionBuilder<SlideElementTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SlideElement.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue> get table => SlideElement.t;
}

class SlideElementRepository {
  const SlideElementRepository._();

  final attachRow = const SlideElementAttachRowRepository._();

  final detachRow = const SlideElementDetachRowRepository._();

  /// Returns a list of [SlideElement]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<SlideElement>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SlideElementTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SlideElementTable>? orderBy,
    _is.OrderByListBuilder<SlideElementTable>? orderByList,
    _is.Transaction? transaction,
    SlideElementInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<SlideElement>(
      where: where?.call(SlideElement.t),
      orderBy: orderBy?.call(SlideElement.t),
      orderByList: orderByList?.call(SlideElement.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [SlideElement]s matching the given query parameters every time the
  /// source tables are modified.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// Use [throttle] to specify the minimum interval between queries. It can
  /// also be set to `null`, in which case the stream will only be throttled
  /// when its subscription is paused.
  ///
  /// Source tables are collected from the queried table, [where], [orderBy],
  /// [orderByList], and the [include] graph. [alsoTriggerOnTables] is added
  /// to that set. Pass [Table] instances such as `SlideElement.t`.
  ///
  /// Raw [Expression] SQL is not inspected. Tables referenced only in raw
  /// SQL must be passed via [alsoTriggerOnTables].
  ///
  /// The stream always reads committed state and never joins an ambient
  /// [Transaction]. Emissions for a write fire after that write commits.
  ///
  /// Currently only supported on SQLite. Calling this method on PostgreSQL
  /// throws an [UnsupportedError].
  ///
  /// ```dart
  /// var subscription = Persons.db.watch(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// ).listen((persons) {
  ///   // Handle the latest matching rows.
  /// });
  /// ```
  _ida.Stream<List<SlideElement>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SlideElementTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SlideElementTable>? orderBy,
    _is.OrderByListBuilder<SlideElementTable>? orderByList,
    SlideElementInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<SlideElement>(
      where: where?.call(SlideElement.t),
      orderBy: orderBy?.call(SlideElement.t),
      orderByList: orderByList?.call(SlideElement.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [SlideElement] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<SlideElement?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SlideElementTable>? where,
    int? offset,
    _is.OrderByBuilder<SlideElementTable>? orderBy,
    _is.OrderByListBuilder<SlideElementTable>? orderByList,
    _is.Transaction? transaction,
    SlideElementInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<SlideElement>(
      where: where?.call(SlideElement.t),
      orderBy: orderBy?.call(SlideElement.t),
      orderByList: orderByList?.call(SlideElement.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [SlideElement] by its [id] or null if no such row exists.
  Future<SlideElement?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    SlideElementInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<SlideElement>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [SlideElement]s in the list and returns the inserted rows.
  ///
  /// The returned [SlideElement]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SlideElement>> insert(
    _is.DatabaseSession session,
    List<SlideElement> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<SlideElement>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [SlideElement] and returns the inserted row.
  ///
  /// The returned [SlideElement] will have its `id` field set.
  Future<SlideElement> insertRow(
    _is.DatabaseSession session,
    SlideElement row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<SlideElement>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [SlideElement]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [SlideElement]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SlideElement>> upsert(
    _is.DatabaseSession session,
    List<SlideElement> rows, {
    required _is.ColumnSelections<SlideElementTable> conflictColumns,
    _is.ColumnSelections<SlideElementTable>? updateColumns,
    _is.WhereExpressionBuilder<SlideElementTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<SlideElement>(
      rows,
      conflictColumns: conflictColumns(SlideElement.t),
      updateColumns: updateColumns?.call(SlideElement.t),
      updateWhere: updateWhere?.call(SlideElement.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [SlideElement] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [SlideElement] will have its `id` field set.
  Future<SlideElement?> upsertRow(
    _is.DatabaseSession session,
    SlideElement row, {
    required _is.ColumnSelections<SlideElementTable> conflictColumns,
    _is.ColumnSelections<SlideElementTable>? updateColumns,
    _is.WhereExpressionBuilder<SlideElementTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<SlideElement>(
      row,
      conflictColumns: conflictColumns(SlideElement.t),
      updateColumns: updateColumns?.call(SlideElement.t),
      updateWhere: updateWhere?.call(SlideElement.t),
      transaction: transaction,
    );
  }

  /// Updates all [SlideElement]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SlideElement>> update(
    _is.DatabaseSession session,
    List<SlideElement> rows, {
    _is.ColumnSelections<SlideElementTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<SlideElement>(
      rows,
      columns: columns?.call(SlideElement.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [SlideElement]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SlideElement> updateRow(
    _is.DatabaseSession session,
    SlideElement row, {
    _is.ColumnSelections<SlideElementTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<SlideElement>(
      row,
      columns: columns?.call(SlideElement.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SlideElement] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SlideElement?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<SlideElementUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<SlideElement>(
      id,
      columnValues: columnValues(SlideElement.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SlideElement]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SlideElement>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<SlideElementUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<SlideElementTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SlideElementTable>? orderBy,
    _is.OrderByListBuilder<SlideElementTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<SlideElement>(
      columnValues: columnValues(SlideElement.t.updateTable),
      where: where(SlideElement.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SlideElement.t),
      orderByList: orderByList?.call(SlideElement.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [SlideElement]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SlideElement>> delete(
    _is.DatabaseSession session,
    List<SlideElement> rows, {
    _is.OrderByBuilder<SlideElementTable>? orderBy,
    _is.OrderByListBuilder<SlideElementTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<SlideElement>(
      rows,
      orderBy: orderBy?.call(SlideElement.t),
      orderByList: orderByList?.call(SlideElement.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [SlideElement].
  Future<SlideElement> deleteRow(
    _is.DatabaseSession session,
    SlideElement row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SlideElement>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SlideElement>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SlideElementTable> where,
    _is.OrderByBuilder<SlideElementTable>? orderBy,
    _is.OrderByListBuilder<SlideElementTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<SlideElement>(
      where: where(SlideElement.t),
      orderBy: orderBy?.call(SlideElement.t),
      orderByList: orderByList?.call(SlideElement.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SlideElementTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<SlideElement>(
      where: where?.call(SlideElement.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [SlideElement] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SlideElementTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<SlideElement>(
      where: where(SlideElement.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class SlideElementAttachRowRepository {
  const SlideElementAttachRowRepository._();

  /// Creates a relation between the given [SlideElement] and [RevFile]
  /// by setting the [SlideElement]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    SlideElement slideElement,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (slideElement.id == null) {
      throw ArgumentError.notNull('slideElement.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $slideElement = slideElement.copyWith(fileId: file.id);
    await session.db.updateRow<SlideElement>(
      $slideElement,
      columns: [SlideElement.t.fileId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [SlideElement] and [Slide]
  /// by setting the [SlideElement]'s foreign key `slideId` to refer to the [Slide].
  Future<void> slide(
    _is.DatabaseSession session,
    SlideElement slideElement,
    _iet418te.Slide slide, {
    _is.Transaction? transaction,
  }) async {
    if (slideElement.id == null) {
      throw ArgumentError.notNull('slideElement.id');
    }
    if (slide.id == null) {
      throw ArgumentError.notNull('slide.id');
    }

    var $slideElement = slideElement.copyWith(slideId: slide.id);
    await session.db.updateRow<SlideElement>(
      $slideElement,
      columns: [SlideElement.t.slideId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [SlideElement] and [SlideLayout]
  /// by setting the [SlideElement]'s foreign key `layoutId` to refer to the [SlideLayout].
  Future<void> layout(
    _is.DatabaseSession session,
    SlideElement slideElement,
    _it7mv5qw.SlideLayout layout, {
    _is.Transaction? transaction,
  }) async {
    if (slideElement.id == null) {
      throw ArgumentError.notNull('slideElement.id');
    }
    if (layout.id == null) {
      throw ArgumentError.notNull('layout.id');
    }

    var $slideElement = slideElement.copyWith(layoutId: layout.id);
    await session.db.updateRow<SlideElement>(
      $slideElement,
      columns: [SlideElement.t.layoutId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [SlideElement] and [SlideMaster]
  /// by setting the [SlideElement]'s foreign key `masterId` to refer to the [SlideMaster].
  Future<void> master(
    _is.DatabaseSession session,
    SlideElement slideElement,
    _iqzg1yqp.SlideMaster master, {
    _is.Transaction? transaction,
  }) async {
    if (slideElement.id == null) {
      throw ArgumentError.notNull('slideElement.id');
    }
    if (master.id == null) {
      throw ArgumentError.notNull('master.id');
    }

    var $slideElement = slideElement.copyWith(masterId: master.id);
    await session.db.updateRow<SlideElement>(
      $slideElement,
      columns: [SlideElement.t.masterId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [SlideElement] and [SlideElement]
  /// by setting the [SlideElement]'s foreign key `parentId` to refer to the [SlideElement].
  Future<void> parent(
    _is.DatabaseSession session,
    SlideElement slideElement,
    _ip9zwo22.SlideElement parent, {
    _is.Transaction? transaction,
  }) async {
    if (slideElement.id == null) {
      throw ArgumentError.notNull('slideElement.id');
    }
    if (parent.id == null) {
      throw ArgumentError.notNull('parent.id');
    }

    var $slideElement = slideElement.copyWith(parentId: parent.id);
    await session.db.updateRow<SlideElement>(
      $slideElement,
      columns: [SlideElement.t.parentId],
      transaction: transaction,
    );
  }
}

class SlideElementDetachRowRepository {
  const SlideElementDetachRowRepository._();

  /// Detaches the relation between this [SlideElement] and the [Slide] set in `slide`
  /// by setting the [SlideElement]'s foreign key `slideId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> slide(
    _is.DatabaseSession session,
    SlideElement slideElement, {
    _is.Transaction? transaction,
  }) async {
    if (slideElement.id == null) {
      throw ArgumentError.notNull('slideElement.id');
    }

    var $slideElement = slideElement.copyWith(slideId: null);
    await session.db.updateRow<SlideElement>(
      $slideElement,
      columns: [SlideElement.t.slideId],
      transaction: transaction,
    );
  }

  /// Detaches the relation between this [SlideElement] and the [SlideLayout] set in `layout`
  /// by setting the [SlideElement]'s foreign key `layoutId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> layout(
    _is.DatabaseSession session,
    SlideElement slideElement, {
    _is.Transaction? transaction,
  }) async {
    if (slideElement.id == null) {
      throw ArgumentError.notNull('slideElement.id');
    }

    var $slideElement = slideElement.copyWith(layoutId: null);
    await session.db.updateRow<SlideElement>(
      $slideElement,
      columns: [SlideElement.t.layoutId],
      transaction: transaction,
    );
  }

  /// Detaches the relation between this [SlideElement] and the [SlideMaster] set in `master`
  /// by setting the [SlideElement]'s foreign key `masterId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> master(
    _is.DatabaseSession session,
    SlideElement slideElement, {
    _is.Transaction? transaction,
  }) async {
    if (slideElement.id == null) {
      throw ArgumentError.notNull('slideElement.id');
    }

    var $slideElement = slideElement.copyWith(masterId: null);
    await session.db.updateRow<SlideElement>(
      $slideElement,
      columns: [SlideElement.t.masterId],
      transaction: transaction,
    );
  }

  /// Detaches the relation between this [SlideElement] and the [SlideElement] set in `parent`
  /// by setting the [SlideElement]'s foreign key `parentId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> parent(
    _is.DatabaseSession session,
    SlideElement slideElement, {
    _is.Transaction? transaction,
  }) async {
    if (slideElement.id == null) {
      throw ArgumentError.notNull('slideElement.id');
    }

    var $slideElement = slideElement.copyWith(parentId: null);
    await session.db.updateRow<SlideElement>(
      $slideElement,
      columns: [SlideElement.t.parentId],
      transaction: transaction,
    );
  }
}
