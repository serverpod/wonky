import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_slides_core/clipboard.dart' show SlidesClipboardCodec;
import 'package:wonky_slides_core/markdown.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/motion.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/schema.dart' show SlidesTables;
import 'package:wonky_slides_core/themes.dart';
import 'package:wonky_sync_models/ids.dart' show SlidesIds;

import '../ai/slides_ai_guard.dart';
import '../../platform/drive/drive_presentations.dart';
import '../../platform/files/file_service.dart';
import '../../platform/mcp/drive_tool_handlers.dart';
import '../../platform/mcp/tool_support.dart';
import 'slides_content.dart';
import 'slides_input.dart';
import 'slides_mcp_support.dart';
import 'slides_read_handlers.dart';
import 'slides_writes.dart';

/// Deck, theme, slide and group tools (Slides 11 §3.5–§3.7) and
/// `drive.create_presentation`.
abstract final class SlidesDeckHandlers {
  /// Slides per outline (11 §3.13).
  static const maxOutlineSlides = 200;

  static String _plural(int n, String one, [String? many]) =>
      '$n ${n == 1 ? one : (many ?? '${one}s')}';

  // ------------------------------------------------------------- create

  static SlideSize? _size(Object? v, {required String pointer}) {
    if (v == null) return null;
    if (v is String) {
      final kind = switch (v) {
        'widescreen' => SlideSizeKind.widescreen16x9,
        'standard' => SlideSizeKind.standard4x3,
        'wide' => SlideSizeKind.wide16x10,
        'square' => SlideSizeKind.square,
        'portrait' => SlideSizeKind.portrait9x16,
        'a4' => SlideSizeKind.a4,
        'letter' => SlideSizeKind.letter,
        _ => throw SlidesMcp.invalid('Unknown size "$v".', pointer: pointer),
      };
      return SlideSize.preset(kind);
    }
    if (v is Map) {
      if (v['preset'] is String) return _size(v['preset'], pointer: pointer);
      final w = (v['width'] as num?)?.toDouble();
      final h = (v['height'] as num?)?.toDouble();
      if (w == null || h == null) {
        throw SlidesMcp.invalid(
          'Give a preset or width and height.',
          pointer: pointer,
        );
      }
      final problem = SlideSize.validate(w, h);
      if (problem != null) throw SlidesMcp.invalid(problem, pointer: pointer);
      return SlideSize.custom(w, h);
    }
    return null;
  }

  static SlideAppearance? _appearance(String? v) => switch (v) {
    'light' => SlideAppearance.light,
    'dark' => SlideAppearance.dark,
    _ => null,
  };

  /// Prepares the images of an outline (copied into the deck).
  static Future<Map<String, PreparedImage>> _outlineImages(
    ToolContext ctx,
    SlidesTarget t,
    DeckOutline outline,
  ) async {
    final out = <String, PreparedImage>{};
    for (final (i, s) in outline.slides.indexed) {
      for (final im in s.images) {
        out[im.fileUuid] ??= await SlidesContent.prepareImage(
          ctx,
          t,
          im.fileUuid,
          pointer: '/markdown/slides/$i/images',
        );
      }
    }
    return out;
  }

  static DeckOutline _parseOutline(String markdown) {
    if (utf8.encode(markdown).length > 200 * 1024) {
      throw McpToolException.limit(
        'The outline can have at most 200 KB.',
        limit: 'markdown_bytes',
        max: 200 * 1024,
      );
    }
    final outline = DeckOutlineCodec.parse(markdown);
    if (outline.slides.length > maxOutlineSlides) {
      throw McpToolException.limit(
        'An outline can add at most $maxOutlineSlides slides '
        '(${outline.slides.length} given).',
        limit: 'slides',
        max: maxOutlineSlides,
      );
    }
    return outline;
  }

  /// `drive.create_presentation` (suite 09 §4, Slides 11 §3.5).
  static Future<ToolResult> createPresentation(
    ToolContext ctx,
    ToolArgs a,
  ) async {
    final theme = a.string('theme');
    if (theme != null && BuiltInThemes.byKey(theme) == null) {
      throw SlidesMcp.invalid(
        'Unknown theme "$theme". Built-in themes: '
        '${BuiltInThemes.keys.join(', ')}.',
        pointer: '/theme',
      );
    }
    final size = _size(a.values['size'], pointer: '/size');
    final appearance = _appearance(a.string('appearance'));
    final markdown = a.string('outline_markdown');
    final outline = markdown == null || markdown.trim().isEmpty
        ? null
        : _parseOutline(markdown);
    final template = a.uuid('template_uuid');
    final view = await DrivePresentations.create(
      ctx.session,
      ctx.actor,
      parentUuid: a.uuid('parent_uuid'),
      name: a.requireString('name'),
      templateUuid: template,
      themeKey: theme,
    );
    final t = await SlidesMcp.openRef(ctx, view.uuid.uuid, min: Role.viewer);
    SlidesWriteOutcome? o;
    var copied = false;
    if (size != null || appearance != null || outline != null) {
      final images = outline == null
          ? const <String, PreparedImage>{}
          : await _outlineImages(ctx, t, outline);
      copied = images.values.any((i) => i.copied);
      final warnings = <SlidesWarning>[];
      o = await SlidesWrites.run(
        ctx,
        t,
        tool: 'drive.create_presentation',
        label: 'create_presentation',
        warnings: warnings,
        build: (s) {
          if (size != null || appearance != null) {
            s.run(
              SetDeckProps(
                size: size == null ? null : DeckSizeChange(size),
                appearance: appearance,
              ),
            );
          }
          if (outline != null && outline.slides.isNotEmpty) {
            final initial = [for (final x in s.model.slides) x.id];
            SlidesContent.addSlides(
              s,
              SlidesContent.fromOutline(outline, images),
              start: const TopLevel(),
              warnings: warnings,
            );
            // A blank deck's empty title slide gives way to the outline.
            if (template == null) {
              final empty = [
                for (final id in initial)
                  if (s.model
                      .allElementsOf(id)
                      .every(
                        (e) => SlidesText.isBlank(e.text),
                      ))
                    id,
              ];
              if (empty.isNotEmpty) s.run(DeleteSlides(empty));
            }
          }
        },
      );
    }
    final model = t.model;
    return ToolResult(
      {
        'item': DriveToolHandlers.itemJson(view),
        'deck_uuid': view.uuid.uuid,
        'url': SlidesReadHandlers.urlOf(t),
        'slide_ids': [for (final s in model.slides) s.id],
        'change_id': o?.write.changeId?.uuid,
        'sync_version': o?.write.syncVersion,
        'warnings': [for (final w in o?.warnings ?? const []) w.toJson()],
        if (copied || template != null)
          'storage': await DriveToolHandlers.storageJson(ctx),
      },
      text:
          'Created presentation "${view.name}" (${view.uuid.uuid}) with '
          '${_plural(model.slides.length, 'slide')}',
    );
  }

  // --------------------------------------------------------- properties

  static Future<ToolResult> setDeckProperties(
    ToolContext ctx,
    ToolArgs a,
  ) async {
    final t = await SlidesMcp.edit(ctx, a);
    final sizeArg = a.object('size');
    final size = _size(sizeArg, pointer: '/size');
    final numbers = a.object('slide_numbers');
    final defaultTransition = a.present('default_transition');
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.set_deck_properties',
      build: (s) {
        final m = s.model;
        s.run(
          SetDeckProps(
            title: a.string('title'),
            size: size == null
                ? null
                : DeckSizeChange(
                    size,
                    mode: sizeArg?['scale_content'] == 'keep'
                        ? SizeScaleMode.keep
                        : SizeScaleMode.scale,
                  ),
            appearance: _appearance(a.string('appearance')),
            showSlideNumbers: numbers?['show'] as bool?,
            hideNumberOnTitle: numbers?['hide_on_title'] as bool?,
            firstSlideNumber: (numbers?['first'] as num?)?.toInt(),
            footerText: a.present('footer_text')
                ? Patch(a.string('footer_text'))
                : null,
            language: a.present('language')
                ? Patch(a.string('language'))
                : null,
          ),
        );
        if (defaultTransition) {
          final tr = a.object('default_transition');
          s.run(
            SetDeckProps(
              defaultsJson: Patch(
                DeckMotionDefaults.withTransition(
                  m.deck?.defaultsJson,
                  tr == null
                      ? TransitionSpec.none
                      : TransitionSpec.decode(
                          SlidesInput.transitionJson(tr),
                        ).value,
                ),
              ),
            ),
          );
        }
      },
    );
    return SlidesWrites.result(o, 'Updated the presentation properties');
  }

  // --------------------------------------------------------------- themes

  static Future<ToolResult> applyTheme(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    final theme = a.values['theme'];
    final slideRefs = a.list('slides');
    final mapping = a.object('layout_mapping') ?? const {};
    String? builtin;
    String? localTheme;
    Map<String, Object?>? entry;
    String? sourceKey;
    if (theme is String) {
      final local = SlidesMcp.canonicalId(theme);
      if (local != null && t.model.theme(local) != null) {
        localTheme = local;
      } else if (BuiltInThemes.byKey(theme) != null) {
        builtin = theme;
      } else {
        throw SlidesMcp.invalid(
          'Unknown theme "$theme". Built-in themes: '
          '${BuiltInThemes.keys.join(', ')}.',
          pointer: '/theme',
        );
      }
    } else if (theme is Map) {
      final themeId = SlidesMcp.canonicalId('${theme['theme_id']}');
      final deckRef = theme['deck'];
      if (deckRef is String &&
          SlidesMcp.parseRef(deckRef) != t.item.uuid &&
          SlidesMcp.parseRef(deckRef) != t.space) {
        final source = await SlidesMcp.openRef(ctx, deckRef);
        final rec = themeId == null ? null : source.model.theme(themeId);
        if (rec == null) {
          throw McpToolException(
            McpErrorCode.notFound,
            'Theme ${theme['theme_id']} not found in that presentation.',
          );
        }
        sourceKey = SlidesIds.deckThemeSourceKey(
          source.item.uuid.uuid,
          rec.id,
        );
        final (payload, rehomes) = SlidesClipboardCodec.rehomeFiles({
          'themes': [SlidesClipboardCodec.themeEntry(source.model, rec)],
        });
        for (final r in rehomes) {
          await FileService.copyToItem(
            ctx.session,
            ctx.actor,
            sourceFileUuid: UuidValue.withValidation(r.sourceFileUuid),
            newFileUuid: UuidValue.withValidation(r.newFileUuid),
            targetItemUuid: t.item.uuid,
          );
        }
        entry = ((payload['themes']! as List).single as Map)
            .cast<String, Object?>();
      } else {
        if (themeId == null || t.model.theme(themeId) == null) {
          throw McpToolException(
            McpErrorCode.notFound,
            'Theme ${theme['theme_id']} not found (slides.list_themes).',
          );
        }
        localTheme = themeId;
      }
    }
    final remapped = <Map<String, Object?>>[];
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.apply_theme',
      confirmIf: () => SlidesAiGuard.themeReason(
        allSlides: slideRefs == null || slideRefs.isEmpty,
        total: t.model.slides.length,
      ),
      build: (s) {
        final m = s.model;
        final slides = SlidesMcp.slideIds(m, slideRefs);
        final all = slides.isEmpty;
        var themeId = localTheme;
        if (builtin != null) {
          themeId =
              s.run(ImportTheme(builtInKey: builtin)).result['themeId']!
                  as String;
        } else if (entry != null) {
          themeId =
              s
                      .run(ImportTheme(themeEntry: entry, sourceKey: sourceKey))
                      .result['themeId']
                  as String? ??
              SlidesIds.themeCopyId(m.deckId, sourceKey!);
        }
        final targets = all ? [for (final x in m.slides) x.id] : slides;
        final before = {
          for (final id in targets)
            id: m.layout(m.slide(id)!.layoutId ?? '')?.key,
        };
        final layoutMap = <String, String>{};
        for (final MapEntry(:key, :value) in mapping.entries) {
          final to = SlidesMcp.layout(m, '$value', themeId: themeId);
          if (to == null) {
            throw SlidesMcp.invalid(
              'The theme has no layout "$value".',
              pointer: '/layout_mapping/$key',
            );
          }
          for (final l in m.records(SlidesTables.slideLayout)) {
            if ((l as SlideLayoutRec).key == key) layoutMap[l.id] = to.id;
          }
        }
        if (m.slides.isEmpty && all) {
          s.run(SetDeckTheme(themeId!));
        } else {
          s.run(
            ApplyThemeToSlides(
              themeId!,
              all ? const [] : slides,
              layoutMapping: layoutMap,
              setDefault: all,
            ),
          );
        }
        for (final id in targets) {
          final after = m.layout(m.slide(id)!.layoutId ?? '')?.key;
          if (after != before[id]) {
            remapped.add({'slide_id': id, 'from': before[id], 'to': after});
          }
        }
      },
    );
    return SlidesWrites.result(o, 'Applied the theme', {
      'remapped': remapped,
    });
  }

  // --------------------------------------------------------------- slides

  static Future<ToolResult> addSlides(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    final list = a.list('slides')!;
    final group = a.values['group'];
    final warnings = <SlidesWarning>[];
    final inputs = [
      for (final (i, raw) in list.indexed)
        if (raw is Map)
          SlideInput(pointer: '/slides/$i')
            ..layout = raw['layout'] as String?
            ..title = raw['title']
            ..body = raw['body']
            ..placeholders =
                (raw['placeholders'] as Map?)?.cast<String, Object?>() ??
                const {}
            ..notes = raw['notes']
            ..background = raw['background']
            ..skipped = raw['skipped'] as bool?
            ..transition = (raw['transition'] as Map?)?.cast<String, Object?>(),
    ];
    var ids = <String>[];
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.add_slides',
      label: 'add_slides (${inputs.length})',
      warnings: warnings,
      build: (s) {
        final m = s.model;
        final groupId = group is String
            ? SlidesMcp.groupId(m, group, pointer: '/group')
            : null;
        ids = SlidesContent.addSlides(
          s,
          inputs,
          start: SlidesContent.target(m, a.object('at'), groupId: groupId),
          warnings: warnings,
        );
        if (group is Map && group['new'] is Map) {
          final n = (group['new'] as Map).cast<String, Object?>();
          s.run(
            CreateGroup(
              ids,
              title: n['title'] as String?,
              color: n['color'] as String?,
            ),
          );
        }
      },
    );
    return _slidesAdded(t, o, ids);
  }

  static ToolResult _slidesAdded(
    SlidesTarget t,
    SlidesWriteOutcome o,
    List<String> ids,
  ) {
    final m = t.model;
    final positions = [for (final id in ids) SlidesMcp.positionOf(m, id)];
    for (final w in SlidesReadHandlers.overflowWarnings(m, ids)) {
      o.warnings.add(
        SlidesWarning(
          '${w['code']}',
          '${w['message']}',
          elementId: w['element_id'] as String?,
        ),
      );
    }
    return SlidesWrites.result(
      o,
      ids.isEmpty
          ? 'No slides added'
          : 'Added ${_plural(ids.length, 'slide')}'
                '${positions.isEmpty ? '' : ' at ${positions.first}'}',
      {
        'slide_ids': ids,
        'positions': positions,
      },
    );
  }

  static Future<ToolResult> addSlidesFromMarkdown(
    ToolContext ctx,
    ToolArgs a,
  ) async {
    final t = await SlidesMcp.edit(ctx, a);
    final outline = _parseOutline(a.requireString('markdown'));
    if (outline.slides.isEmpty) {
      throw SlidesMcp.invalid(
        'The outline has no slides.',
        pointer: '/markdown',
      );
    }
    final images = await _outlineImages(ctx, t, outline);
    final warnings = <SlidesWarning>[];
    var ids = <String>[];
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.add_slides_from_markdown',
      label: 'add_slides_from_markdown (${outline.slides.length})',
      warnings: warnings,
      build: (s) {
        ids = SlidesContent.addSlides(
          s,
          SlidesContent.fromOutline(outline, images),
          start: SlidesContent.target(s.model, a.object('at')),
          warnings: warnings,
        );
      },
    );
    final r = _slidesAdded(t, o, ids);
    if (!images.values.any((i) => i.copied)) return r;
    return ToolResult({
      ...(r.structured! as Map).cast<String, Object?>(),
      'storage': await DriveToolHandlers.storageJson(ctx),
    }, text: r.text);
  }

  static Future<ToolResult> updateSlide(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    final warnings = <SlidesWarning>[];
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.update_slide',
      force: a.boolean('force') ?? false,
      warnings: warnings,
      build: (s) {
        final m = s.model;
        final id = SlidesMcp.slideId(m, a.values['slide']);
        String? layoutId;
        if (a.string('layout') case final String key) {
          final l = SlidesMcp.layout(
            m,
            key,
            themeId: SlidesMcp.themeOfSlide(m, id),
          );
          if (l == null) {
            throw SlidesMcp.invalid(
              'Unknown layout "$key". Layouts: '
              '${SlidesMcp.layoutKeys(m).join(', ')}.',
              pointer: '/layout',
            );
          }
          layoutId = l.id;
        }
        s.run(
          SetSlideProps(
            [id],
            layoutId: layoutId,
            skipped: a.boolean('skipped'),
            backgroundJson: a.present('background')
                ? Patch(
                    a.values['background'] == null
                        ? null
                        : SlidesInput.background(
                            a.values['background'],
                            pointer: '/background',
                          ),
                  )
                : null,
            notes: a.present('notes')
                ? Patch(
                    SlidesInput.text(
                      m,
                      a.values['notes'],
                      notes: true,
                      pointer: '/notes',
                      warnings: warnings,
                    ),
                  )
                : null,
            hideMasterElements: a.present('hide_master_elements')
                ? Patch(a.boolean('hide_master_elements'))
                : null,
            transitionJson: a.present('transition')
                ? Patch(
                    a.object('transition') == null
                        ? null
                        : SlidesInput.transitionJson(a.object('transition')!),
                  )
                : null,
          ),
        );
        if (layoutId != null && a.boolean('keep_content') == false) {
          final clear = [
            for (final e in s.model.elementsOf(id))
              if (e.placeholderType != null && !SlidesText.isBlank(e.text))
                e.id,
          ];
          for (final e in clear) {
            s.run(SetText(ElementText(e), null));
          }
        }
      },
    );
    return SlidesWrites.result(o, 'Updated the slide');
  }

  static Future<ToolResult> setSpeakerNotes(
    ToolContext ctx,
    ToolArgs a,
  ) async {
    final t = await SlidesMcp.edit(ctx, a);
    final list = a.list('notes')!;
    final warnings = <SlidesWarning>[];
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.set_speaker_notes',
      label: 'set_speaker_notes (${list.length})',
      force: a.boolean('force') ?? false,
      warnings: warnings,
      build: (s) {
        final m = s.model;
        for (final (i, raw) in list.indexed) {
          final n = (raw! as Map).cast<String, Object?>();
          final id = SlidesMcp.slideId(
            m,
            n['slide'],
            pointer: '/notes/$i/slide',
          );
          var delta = SlidesInput.text(
            m,
            n['notes'],
            notes: true,
            pointer: '/notes/$i/notes',
            warnings: warnings,
          );
          if (n['mode'] == 'append') {
            delta = SlidesMarkdownCodec.concat(
              m.slide(id)!.notes,
              delta,
              notes: true,
            );
          }
          s.run(SetSlideProps([id], notes: Patch(delta)));
        }
      },
    );
    return SlidesWrites.result(
      o,
      'Set the notes of ${_plural(list.length, 'slide')}',
    );
  }

  static Future<ToolResult> moveSlides(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    final to = a.object('to')!;
    late List<String> ids;
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.move_slides',
      build: (s) {
        final m = s.model;
        ids = SlidesMcp.slideIds(m, a.list('slides'));
        final moving = ids.toSet();
        SlideTarget target;
        if (to['group'] is String) {
          final g = SlidesMcp.groupId(
            m,
            to['group'] as String,
            pointer: '/to/group',
          );
          final members = [
            for (final x in m.slidesInGroup(g))
              if (!moving.contains(x.id)) x.id,
          ];
          final pos = (to['position'] as num?)?.toInt();
          target = pos == null || pos > members.length
              ? InGroup(g)
              : InGroup(g, beforeId: members[pos - 1]);
        } else if (to['top_level'] == true) {
          final first = m.slide(ids.first)!;
          final g = first.groupId;
          target = g == null
              ? TopLevel(beforeId: first.id)
              : TopLevel(afterId: g);
        } else if (to['position'] != null) {
          final pos = (to['position'] as num).toInt();
          final rest = [
            for (final x in m.slides)
              if (!moving.contains(x.id)) x,
          ];
          if (pos > rest.length) {
            target = const TopLevel();
          } else {
            final ref = rest[pos - 1];
            target = ref.groupId == null
                ? TopLevel(beforeId: ref.id)
                : InGroup(ref.groupId!, beforeId: ref.id);
          }
        } else if (to['after'] != null || to['before'] != null) {
          final isAfter = to['after'] != null;
          final ref = SlidesMcp.slideId(
            m,
            to[isAfter ? 'after' : 'before'],
            pointer: '/to/${isAfter ? 'after' : 'before'}',
          );
          if (moving.contains(ref)) {
            throw SlidesMcp.invalid(
              'The reference slide is one of the moved slides.',
              pointer: '/to',
            );
          }
          final g = m.slide(ref)!.groupId;
          target = g == null
              ? TopLevel(
                  afterId: isAfter ? ref : null,
                  beforeId: isAfter ? null : ref,
                )
              : InGroup(
                  g,
                  afterId: isAfter ? ref : null,
                  beforeId: isAfter ? null : ref,
                );
        } else {
          throw SlidesMcp.invalid(
            'to needs position, after, before, group or top_level.',
            pointer: '/to',
          );
        }
        s.run(MoveSlides(ids, target));
      },
    );
    final m = t.model;
    return SlidesWrites.result(
      o,
      'Moved ${_plural(ids.length, 'slide')} to '
      '${SlidesMcp.positionOf(m, ids.first)}',
      {
        'positions': [for (final id in ids) SlidesMcp.positionOf(m, id)],
      },
    );
  }

  static Future<ToolResult> duplicateSlides(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    var n = 0;
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.duplicate_slides',
      build: (s) {
        final ids = SlidesMcp.slideIds(s.model, a.list('slides'));
        n = ids.length;
        s.run(DuplicateSlides(ids));
      },
    );
    return SlidesWrites.result(o, 'Duplicated ${_plural(n, 'slide')}');
  }

  static Future<ToolResult> deleteSlides(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    var n = 0;
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.delete_slides',
      label: 'delete_slides (${a.list('slides')!.length})',
      build: (s) {
        final ids = SlidesMcp.slideIds(s.model, a.list('slides'));
        n = ids.length;
        s.run(DeleteSlides(ids));
      },
    );
    return SlidesWrites.result(o, 'Deleted ${_plural(n, 'slide')}');
  }

  // --------------------------------------------------------------- groups

  static Future<ToolResult> createGroup(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    String? groupId;
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.create_group',
      build: (s) {
        final ids = SlidesMcp.slideIds(s.model, a.list('slides'));
        final plan = s.run(
          CreateGroup(
            ids,
            title: a.string('title'),
            color: a.string('color'),
            target: ids.isEmpty ? const TopLevel() : null,
          ),
        );
        groupId = plan.result['groupId'] as String?;
      },
    );
    return SlidesWrites.result(o, 'Created the group "${a.string('title')}"', {
      'group_id': groupId,
    });
  }

  static Future<ToolResult> updateGroup(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.update_group',
      build: (s) {
        final g = SlidesMcp.groupId(s.model, a.string('group_id'));
        s.run(
          SetGroupProps(
            [g],
            title: a.string('title'),
            color: a.present('color') ? Patch(a.string('color')) : null,
            skipped: a.boolean('skipped'),
          ),
        );
      },
    );
    return SlidesWrites.result(o, 'Updated the group');
  }

  static Future<ToolResult> moveGroup(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    final to = a.object('to')!;
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.move_group',
      build: (s) {
        final m = s.model;
        final g = SlidesMcp.groupId(m, a.string('group_id'));
        String? before, after;
        String topOf(String slideId) {
          final x = m.slide(slideId)!;
          return x.groupId ?? x.id;
        }

        if (to['after_group'] is String) {
          after = SlidesMcp.groupId(
            m,
            to['after_group'] as String,
            pointer: '/to/after_group',
          );
        } else if (to['before_group'] is String) {
          before = SlidesMcp.groupId(
            m,
            to['before_group'] as String,
            pointer: '/to/before_group',
          );
        } else if (to['after_slide'] != null) {
          after = topOf(
            SlidesMcp.slideId(m, to['after_slide'], pointer: '/to/after_slide'),
          );
        } else if (to['before_slide'] != null) {
          before = topOf(
            SlidesMcp.slideId(
              m,
              to['before_slide'],
              pointer: '/to/before_slide',
            ),
          );
        } else if (to['position'] != null) {
          final pos = (to['position'] as num).toInt();
          final rest = [
            for (final x in m.slides)
              if (x.groupId != g) x,
          ];
          if (pos <= rest.length) before = topOf(rest[pos - 1].id);
        } else {
          throw SlidesMcp.invalid(
            'to needs position, after_group, before_group, after_slide or '
            'before_slide.',
            pointer: '/to',
          );
        }
        if (before == g || after == g) return;
        s.run(MoveGroups([g], beforeId: before, afterId: after));
      },
    );
    return SlidesWrites.result(o, 'Moved the group');
  }

  static Future<ToolResult> duplicateGroup(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.duplicate_group',
      build: (s) => s.run(
        DuplicateGroups([SlidesMcp.groupId(s.model, a.string('group_id'))]),
      ),
    );
    return SlidesWrites.result(o, 'Duplicated the group');
  }

  static Future<ToolResult> ungroup(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.ungroup',
      build: (s) =>
          s.run(Ungroup(SlidesMcp.groupId(s.model, a.string('group_id')))),
    );
    return SlidesWrites.result(o, 'Ungrouped the slides');
  }

  static Future<ToolResult> deleteGroup(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    final withSlides = a.boolean('delete_slides') ?? false;
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.delete_group',
      build: (s) => s.run(
        DeleteGroups([
          SlidesMcp.groupId(s.model, a.string('group_id')),
        ], withSlides: withSlides),
      ),
    );
    return SlidesWrites.result(
      o,
      withSlides ? 'Deleted the group and its slides' : 'Deleted the group',
    );
  }
}
