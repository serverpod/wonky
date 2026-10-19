import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_slides_core/ai.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../../l10n/slides_l10n.dart';
import 'ai_widgets.dart';
import 'slides_ai_api.dart';

/// Where *Generate presentation* puts the slides.
enum GenerateTarget { newDeck, afterCurrent, end }

/// What *Generate presentation* produced.
class GenerateDeckResult {
  const GenerateDeckResult(this.build, this.target);
  final SlidesAiBuildResult build;
  final GenerateTarget target;
}

/// Stable widget keys of the Generate dialog.
abstract final class GenerateDeckKeys {
  static const dialog = ValueKey<String>('dialog.slides.generateDeck');
  static const text = ValueKey<String>('dialog.slides.generateDeck.text');
  static const createOutline = ValueKey<String>(
    'dialog.slides.generateDeck.createOutline',
  );
  static const build = ValueKey<String>('dialog.slides.generateDeck.build');
  static const back = ValueKey<String>('dialog.slides.generateDeck.back');
  static const regenerate = ValueKey<String>(
    'dialog.slides.generateDeck.regenerate',
  );
  static const addSlide = ValueKey<String>(
    'dialog.slides.generateDeck.addSlide',
  );
  static ValueKey<String> slideTitle(int i) =>
      ValueKey<String>('dialog.slides.generateDeck.slide.$i.title');
  static ValueKey<String> slideBullets(int i) =>
      ValueKey<String>('dialog.slides.generateDeck.slide.$i.bullets');
  static ValueKey<String> deleteSlide(int i) =>
      ValueKey<String>('dialog.slides.generateDeck.slide.$i.delete');
  static ValueKey<String> regenerateSlide(int i) =>
      ValueKey<String>('dialog.slides.generateDeck.slide.$i.regenerate');
}

/// *Generate presentation* (Slides 11 §6.4): step 1 asks what the deck is
/// about (a prompt or a pasted outline, slide count, audience, tone,
/// language, notes, sections, where to insert), the server proposes an
/// outline (streamed); step 2 shows it as an editable list (titles, roles,
/// bullets; reorder, delete, add, regenerate one slide or all); *Create
/// slides* builds it deterministically on the server. MCP-operable
/// ([McpDescribableDialog]: fields, `outline` as JSON, buttons per step).
///
/// [itemUuid] is the open deck (null: only a new presentation);
/// [currentPosition] the current slide's position (insert after it).
Future<GenerateDeckResult?> showGenerateDeckDialog(
  BuildContext context, {
  required ShellServices services,
  required SlidesAiApi api,
  UuidValue? itemUuid,
  String? afterSlideId,
  int? currentPosition,
  String? prompt,
  String source = 'prompt',
}) => showShadDialog<GenerateDeckResult>(
  context: context,
  builder: (_) => GenerateDeckDialog(
    services: services,
    api: api,
    itemUuid: itemUuid,
    afterSlideId: afterSlideId,
    currentPosition: currentPosition,
    prompt: prompt,
    source: source,
  ),
);

class GenerateDeckDialog extends StatefulWidget {
  const GenerateDeckDialog({
    super.key,
    required this.services,
    required this.api,
    this.itemUuid,
    this.afterSlideId,
    this.currentPosition,
    this.prompt,
    this.source = 'prompt',
  });

  final ShellServices services;
  final SlidesAiApi api;
  final UuidValue? itemUuid;
  final String? afterSlideId;
  final int? currentPosition;
  final String? prompt;
  final String source;

  @override
  State<GenerateDeckDialog> createState() => _GenerateDeckDialogState();
}

enum _Step { options, planning, outline, building }

class _GenerateDeckDialogState extends State<GenerateDeckDialog>
    implements McpDescribableDialog {
  ShellServices? _registeredIn;
  _Step _step = _Step.options;
  late String _source = widget.source == 'outline' ? 'outline' : 'prompt';
  late final TextEditingController _text = TextEditingController(
    text: widget.prompt ?? '',
  );
  int? _slides;
  String _audience = 'general';
  String _tone = 'professional';
  String? _language;
  bool _notes = true;
  bool _groups = true;
  bool _keepWording = false;
  late GenerateTarget _target = widget.itemUuid == null
      ? GenerateTarget.newDeck
      : widget.afterSlideId != null
      ? GenerateTarget.afterCurrent
      : GenerateTarget.end;
  AiOutline? _outline;
  final StringBuffer _progress = StringBuffer();
  StreamSubscription<InlineAiEvent>? _sub;
  String? _error;

  /// Per-slide text controllers of the outline step (rebuilt with it).
  final List<(TextEditingController, TextEditingController)> _fields = [];

  static const _slideCounts = <int?>[null, 3, 5, 8, 10, 12, 15, 20];
  static const _audiences = [
    'general',
    'board',
    'team',
    'customers',
    'students',
    'developers',
  ];
  static const _tones = [
    'professional',
    'friendly',
    'inspiring',
    'technical',
    'concise',
  ];
  static const _languages = <String?>[
    null,
    'English',
    'Svenska',
    'Deutsch',
    'Français',
    'Español',
    'Italiano',
    'Nederlands',
    'Português',
    '日本語',
  ];

  SlidesLocalizations get l => slidesL10nOf(widget.services);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = ShellScope.maybeOf(context);
    _registeredIn = s;
    if (s != null && !s.openDialogs.contains(this)) s.openDialogs.add(this);
  }

  @override
  void dispose() {
    _registeredIn?.openDialogs.remove(this);
    unawaited(_sub?.cancel());
    _text.dispose();
    _disposeFields();
    super.dispose();
  }

  void _disposeFields() {
    for (final (a, b) in _fields) {
      a.dispose();
      b.dispose();
    }
    _fields.clear();
  }

  /// Rebuilds the text controllers from [_outline].
  void _syncFields() {
    _disposeFields();
    for (final s in _outline?.slides ?? const <AiOutlineSlide>[]) {
      _fields.add((
        TextEditingController(text: s.title),
        TextEditingController(
          text: [for (final b in s.bullets) b.text].join('\n'),
        ),
      ));
    }
  }

  /// Writes the text fields back into [_outline].
  void _readFields() {
    final o = _outline;
    if (o == null) return;
    for (final (i, s) in o.slides.indexed) {
      if (i >= _fields.length) break;
      s.title = _fields[i].$1.text.trim();
      final lines = [
        for (final line in _fields[i].$2.text.split('\n'))
          if (line.trim().isNotEmpty) line.trim(),
      ];
      final old = s.bullets.toList();
      s.bullets
        ..clear()
        ..addAll([
          for (final (j, t) in lines.indexed)
            AiOutlineBullet(
              t,
              j < old.length && old[j].text == t ? old[j].children : null,
            ),
        ]);
    }
  }

  String _audienceText(String a) => switch (a) {
    'board' => l.aiAudienceBoard,
    'team' => l.aiAudienceTeam,
    'customers' => l.aiAudienceCustomers,
    'students' => l.aiAudienceStudents,
    'developers' => l.aiAudienceDevelopers,
    _ => l.aiAudienceGeneral,
  };

  String _toneText(String t) => switch (t) {
    'friendly' => l.aiToneFriendly,
    'inspiring' => l.aiToneInspiring,
    'technical' => l.aiToneTechnical,
    'concise' => l.aiToneConcise,
    _ => l.aiToneProfessional,
  };

  String _roleText(AiSlideRole r) => switch (r) {
    AiSlideRole.title => l.aiRoleTitle,
    AiSlideRole.section => l.aiRoleSection,
    AiSlideRole.agenda => l.aiRoleAgenda,
    AiSlideRole.bullets => l.aiRoleBullets,
    AiSlideRole.twoColumn => l.aiRoleTwoColumn,
    AiSlideRole.quote => l.aiRoleQuote,
    AiSlideRole.bigNumber => l.aiRoleBigNumber,
    AiSlideRole.imageText => l.aiRoleImageText,
    AiSlideRole.code => l.aiRoleCode,
    AiSlideRole.chartPlaceholder => l.aiRoleChartPlaceholder,
    AiSlideRole.closing => l.aiRoleClosing,
  };

  String _targetText(GenerateTarget t) => switch (t) {
    GenerateTarget.newDeck => l.aiGenerateInsertNew,
    GenerateTarget.afterCurrent => l.aiGenerateInsertAfter(
      widget.currentPosition ?? 1,
    ),
    GenerateTarget.end => l.aiGenerateInsertEnd,
  };

  List<GenerateTarget> get _targets => [
    GenerateTarget.newDeck,
    if (widget.itemUuid != null && widget.afterSlideId != null)
      GenerateTarget.afterCurrent,
    if (widget.itemUuid != null) GenerateTarget.end,
  ];

  // ----------------------------------------------------------- actions

  SlidesAiOutlineRequest _request({int? slideIndex, String? instruction}) =>
      SlidesAiOutlineRequest(
        source: _source,
        text: _text.text,
        slideCount: _slides,
        audience: _audience,
        tone: _tone,
        language: _language,
        speakerNotes: _notes,
        groups: _groups,
        keepWording: _source == 'outline' && _keepWording,
        outlineJson: slideIndex == null ? null : _outline?.encode(),
        slideIndex: slideIndex,
        instruction: instruction,
      );

  bool get _canPlan => _text.text.trim().isNotEmpty && _step == _Step.options;

  /// Step 1 (or [slideIndex]: regenerate one slide of the outline).
  void _plan({int? slideIndex, String? instruction}) {
    if (slideIndex == null && _text.text.trim().isEmpty) {
      setState(() => _error = l.aiGenerateEmpty);
      return;
    }
    _readFields();
    final back = _step == _Step.outline ? _Step.outline : _Step.options;
    setState(() {
      _step = _Step.planning;
      _error = null;
      _progress.clear();
    });
    final isNewDeck = _target == GenerateTarget.newDeck;
    unawaited(_sub?.cancel());
    _sub = widget.api
        .proposeOutline(
          isNewDeck ? null : widget.itemUuid,
          _request(slideIndex: slideIndex, instruction: instruction),
        )
        .listen(
          (e) {
            if (!mounted) return;
            switch (e.type) {
              case InlineAiEventType.textDelta:
                setState(() => _progress.write(e.text ?? ''));
              case InlineAiEventType.done:
                final o = AiOutline.tryDecode(e.markdown);
                setState(() {
                  if (o == null || o.slideCount == 0) {
                    _step = back;
                    _error = l.aiFailed;
                  } else {
                    _outline = o;
                    _syncFields();
                    _step = _Step.outline;
                  }
                });
              case InlineAiEventType.refusal || InlineAiEventType.error:
                setState(() {
                  _step = back;
                  _error = e.error ?? l.aiFailed;
                });
            }
          },
          onError: (Object err) {
            if (!mounted) return;
            setState(() {
              _step = back;
              _error = errorMessage(err);
            });
          },
        );
  }

  Future<void> _build() async {
    final o = _outline;
    if (o == null || _step != _Step.outline) return;
    _readFields();
    if (o.slideCount == 0) return;
    setState(() {
      _step = _Step.building;
      _error = null;
    });
    final target = _target;
    try {
      final r = await widget.api.buildDeck(
        itemUuid: target == GenerateTarget.newDeck ? null : widget.itemUuid,
        outlineJson: o.encode(),
        afterSlideId: target == GenerateTarget.afterCurrent
            ? widget.afterSlideId
            : null,
        notes: _notes,
        groups: _groups,
      );
      if (mounted) Navigator.of(context).pop(GenerateDeckResult(r, target));
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _step = _Step.outline;
          _error = errorMessage(e);
        });
      }
    }
  }

  void _back() {
    _readFields();
    setState(() {
      _step = _Step.options;
      _error = null;
    });
  }

  void _cancel() {
    unawaited(_sub?.cancel());
    Navigator.of(context).pop();
  }

  void _editOutline(void Function(AiOutline o) edit) {
    final o = _outline;
    if (o == null) return;
    _readFields();
    setState(() {
      edit(o);
      o.groups.removeWhere((g) => g.slides.isEmpty);
      _syncFields();
    });
  }

  (AiOutlineGroup, int)? _locate(int index) {
    var i = 0;
    for (final g in _outline?.groups ?? const <AiOutlineGroup>[]) {
      for (var j = 0; j < g.slides.length; j++) {
        if (i == index) return (g, j);
        i++;
      }
    }
    return null;
  }

  void _deleteSlide(int index) => _editOutline((o) {
    final at = _locate(index);
    if (at != null) at.$1.slides.removeAt(at.$2);
  });

  void _move(int index, int delta) => _editOutline((o) {
    final slides = o.slides.toList();
    final to = index + delta;
    if (to < 0 || to >= slides.length) return;
    final a = _locate(index)!;
    final b = _locate(to)!;
    final x = a.$1.slides[a.$2];
    a.$1.slides[a.$2] = b.$1.slides[b.$2];
    b.$1.slides[b.$2] = x;
  });

  void _addSlide() => _editOutline((o) {
    if (o.groups.isEmpty) o.groups.add(AiOutlineGroup());
    o.groups.last.slides.add(AiOutlineSlide(title: l.aiGenerateNewSlide));
  });

  void _setRole(int index, AiSlideRole role) {
    final at = _locate(index);
    if (at == null) return;
    setState(() => at.$1.slides[at.$2].role = role);
  }

  Future<void> _regenerateSlide(int index) async {
    final r = await showWonkyFormDialog(
      context,
      WonkyDialogSpec(
        title: l.aiGenerateRegenerateSlide,
        dialogKey: 'dialog.slides.generateDeck.regenerateSlide',
        fields: [
          TextFieldSpec(
            id: 'instruction',
            label: l.aiGenerateRegenerateHint,
            maxLength: 500,
          ),
        ],
        buttons: [
          DialogButtonSpec(
            id: 'cancel',
            label: WonkyAppLocalizations.of(context).actionCancel,
          ),
          DialogButtonSpec(
            id: 'ok',
            label: l.aiGenerateRegenerate,
            primary: true,
          ),
        ],
      ),
    );
    if (r?.buttonId != 'ok' || !mounted) return;
    _plan(slideIndex: index, instruction: r!.text('instruction').trim());
  }

  // ------------------------------------------------------------------ MCP

  @override
  Map<String, Object?> describe() {
    final o = _outline;
    final step = _step.name;
    return {
      'title': l.aiGenerateTitle,
      'step': step,
      'error': ?_error,
      if (_step == _Step.planning) 'progress': _progress.toString(),
      'fields': [
        if (_step == _Step.options) ...[
          {
            'id': 'source',
            'label': l.aiGenerateSource,
            'type': 'select',
            'value': _source,
            'options': ['prompt', 'outline'],
          },
          {
            'id': 'text',
            'label': _source == 'outline'
                ? l.aiGenerateOutlineLabel
                : l.aiGeneratePromptLabel,
            'type': 'text',
            'value': _text.text,
          },
          {
            'id': 'slides',
            'label': l.aiGenerateSlides,
            'type': 'select',
            'value': _slides?.toString() ?? 'auto',
            'options': [for (final n in _slideCounts) n?.toString() ?? 'auto'],
          },
          {
            'id': 'audience',
            'label': l.aiGenerateAudience,
            'type': 'select',
            'value': _audience,
            'options': _audiences,
          },
          {
            'id': 'tone',
            'label': l.aiGenerateTone,
            'type': 'select',
            'value': _tone,
            'options': _tones,
          },
          {
            'id': 'language',
            'label': l.aiGenerateLanguage,
            'type': 'select',
            'value': _language ?? 'auto',
            'options': [for (final x in _languages) x ?? 'auto'],
          },
          {
            'id': 'notes',
            'label': l.aiGenerateNotes,
            'type': 'checkbox',
            'value': _notes,
          },
          {
            'id': 'groups',
            'label': l.aiGenerateGroups,
            'type': 'checkbox',
            'value': _groups,
          },
          if (_source == 'outline')
            {
              'id': 'keepWording',
              'label': l.aiGenerateKeepWording,
              'type': 'checkbox',
              'value': _keepWording,
            },
          {
            'id': 'insert',
            'label': l.aiGenerateInsert,
            'type': 'select',
            'value': _target.name,
            'options': [for (final t in _targets) t.name],
          },
        ],
        if (_step == _Step.outline && o != null)
          {
            'id': 'outline',
            'label': l.aiGenerateOutlineTitle,
            'type': 'json',
            'value': o.encode(),
          },
      ],
      if (_step == _Step.outline && o != null)
        'slides': [
          for (final (i, s) in o.slides.indexed)
            {
              'index': i,
              'title': s.title,
              'role': s.role.name,
              'bullets': [for (final b in s.bullets) b.text],
            },
        ],
      'buttons': switch (_step) {
        _Step.options => [
          {'id': 'cancel', 'label': 'Cancel', 'enabled': true},
          {
            'id': 'createOutline',
            'label': l.aiGenerateCreateOutline,
            'enabled': _canPlan,
          },
        ],
        _Step.outline => [
          {'id': 'back', 'label': l.aiGenerateBack, 'enabled': true},
          {
            'id': 'regenerate',
            'label': l.aiGenerateRegenerate,
            'enabled': true,
          },
          {'id': 'addSlide', 'label': l.aiGenerateAddSlide, 'enabled': true},
          {
            'id': 'build',
            'label': l.aiGenerateBuild,
            'enabled': (o?.slideCount ?? 0) > 0,
          },
        ],
        _ => [
          {'id': 'cancel', 'label': 'Cancel', 'enabled': true},
        ],
      },
    };
  }

  @override
  bool setField(String id, Object? value) {
    if (_step == _Step.outline) {
      if (id == 'outline' && value is String) {
        final o = AiOutline.tryDecode(value);
        if (o == null) return false;
        setState(() {
          _outline = o;
          _syncFields();
        });
        return true;
      }
      final m = RegExp(r'^slide\.(\d+)\.(title|role|bullets)$').firstMatch(id);
      if (m == null) return false;
      final i = int.parse(m.group(1)!);
      if (i >= _fields.length) return false;
      switch (m.group(2)) {
        case 'title':
          _fields[i].$1.text = '${value ?? ''}';
        case 'bullets':
          _fields[i].$2.text = value is List
              ? value.join('\n')
              : '${value ?? ''}';
        case 'role':
          final role = AiSlideRole.fromName(value);
          if (role == null) return false;
          _setRole(i, role);
      }
      setState(() {});
      return true;
    }
    if (_step != _Step.options) return false;
    switch (id) {
      case 'source':
        if (value != 'prompt' && value != 'outline') return false;
        setState(() => _source = value! as String);
      case 'text':
        _text.text = '${value ?? ''}';
        setState(() {});
      case 'slides':
        final n = value == 'auto' || value == null
            ? null
            : int.tryParse('$value');
        if (value != 'auto' && value != null && n == null) return false;
        setState(() => _slides = n);
      case 'audience':
        if (!_audiences.contains(value)) return false;
        setState(() => _audience = value! as String);
      case 'tone':
        if (!_tones.contains(value)) return false;
        setState(() => _tone = value! as String);
      case 'language':
        final v = value == 'auto' ? null : value;
        if (!_languages.contains(v)) return false;
        setState(() => _language = v as String?);
      case 'notes':
        setState(() => _notes = value == true);
      case 'groups':
        setState(() => _groups = value == true);
      case 'keepWording':
        setState(() => _keepWording = value == true);
      case 'insert':
        final t = _targets.where((x) => x.name == value).firstOrNull;
        if (t == null) return false;
        setState(() => _target = t);
      default:
        return false;
    }
    return true;
  }

  @override
  bool press(String buttonId) {
    final regen = RegExp(r'^regenerateSlide\.(\d+)$').firstMatch(buttonId);
    final del = RegExp(r'^deleteSlide\.(\d+)$').firstMatch(buttonId);
    switch (buttonId) {
      case 'cancel':
        _cancel();
        return true;
      case 'createOutline' when _canPlan:
        _plan();
        return true;
      case 'back' when _step == _Step.outline:
        _back();
        return true;
      case 'regenerate' when _step == _Step.outline:
        _plan();
        return true;
      case 'addSlide' when _step == _Step.outline:
        _addSlide();
        return true;
      case 'build' when _step == _Step.outline:
        unawaited(_build());
        return true;
    }
    if (_step == _Step.outline && regen != null) {
      _plan(slideIndex: int.parse(regen.group(1)!));
      return true;
    }
    if (_step == _Step.outline && del != null) {
      _deleteSlide(int.parse(del.group(1)!));
      return true;
    }
    return false;
  }

  // ------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final la = WonkyAppLocalizations.of(context);
    final busy = _step == _Step.planning || _step == _Step.building;
    final o = _outline;
    return ShadDialog(
      closeIcon: const WonkyDialogCloseButton(),
      constraints: const BoxConstraints(maxWidth: 760),
      key: GenerateDeckKeys.dialog,
      title: Text(
        _step == _Step.outline ? l.aiGenerateOutlineTitle : l.aiGenerateTitle,
      ),
      description: _step == _Step.outline
          ? Text(
              '${l.aiGenerateOutlineDescription} '
              '${l.aiGenerateSlideCount(o?.slideCount ?? 0)}',
            )
          : null,
      actions: [
        if (_step == _Step.outline) ...[
          ShadButton.outline(
            key: GenerateDeckKeys.back,
            onPressed: _back,
            child: Text(l.aiGenerateBack),
          ),
          ShadButton.outline(
            key: GenerateDeckKeys.regenerate,
            leading: const Icon(LucideIcons.refreshCw, size: 14),
            onPressed: _plan,
            child: Text(l.aiGenerateRegenerate),
          ),
          ShadButton(
            key: GenerateDeckKeys.build,
            enabled: (o?.slideCount ?? 0) > 0,
            onPressed: () => unawaited(_build()),
            child: Text(l.aiGenerateBuild),
          ),
        ] else ...[
          ShadButton.outline(onPressed: _cancel, child: Text(la.actionCancel)),
          if (!busy)
            ShadButton(
              key: GenerateDeckKeys.createOutline,
              enabled: _canPlan,
              trailing: const Icon(LucideIcons.arrowRight, size: 14),
              onPressed: _plan,
              child: Text(l.aiGenerateCreateOutline),
            ),
        ],
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 600),
        child: SizedBox(
          width: 720,
          child: switch (_step) {
            _Step.options => _options(context),
            _Step.planning => AiWorking(
              label: l.aiGeneratePlanning,
              detail: _progress.toString(),
            ),
            _Step.building => AiWorking(label: l.aiGenerateBuilding),
            _Step.outline => _outlineEditor(context),
          },
        ),
      ),
    );
  }

  Widget _options(BuildContext context) {
    final outline = _source == 'outline';
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          if (_error != null) AiError(_error!),
          AiField(
            label: l.aiGenerateSource,
            child: Wrap(
              spacing: 8,
              children: [
                for (final (id, text) in [
                  ('prompt', l.aiGenerateSourcePrompt),
                  ('outline', l.aiGenerateSourceOutline),
                ])
                  _source == id
                      ? ShadButton.secondary(
                          key: ValueKey<String>(
                            'dialog.slides.generateDeck.source.$id',
                          ),
                          size: ShadButtonSize.sm,
                          onPressed: () {},
                          child: Text(text),
                        )
                      : ShadButton.ghost(
                          key: ValueKey<String>(
                            'dialog.slides.generateDeck.source.$id',
                          ),
                          size: ShadButtonSize.sm,
                          onPressed: () => setState(() => _source = id),
                          child: Text(text),
                        ),
              ],
            ),
          ),
          AiField(
            label: outline ? l.aiGenerateOutlineLabel : l.aiGeneratePromptLabel,
            child: ShadInput(
              key: GenerateDeckKeys.text,
              controller: _text,
              minLines: outline ? 6 : 3,
              maxLines: outline ? 12 : 6,
              autofocus: true,
              placeholder: Text(
                outline ? l.aiGenerateOutlineHint : l.aiGeneratePromptHint,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AiField(
                label: l.aiGenerateSlides,
                child: aiSelect<int?>(
                  id: 'dialog.slides.generateDeck.slides',
                  value: _slides,
                  values: _slideCounts,
                  minWidth: 100,
                  text: (n) => n?.toString() ?? l.aiGenerateSlidesAuto,
                  onChanged: (n) => setState(() => _slides = n),
                ),
              ),
              AiField(
                label: l.aiGenerateAudience,
                child: aiSelect<String>(
                  id: 'dialog.slides.generateDeck.audience',
                  value: _audience,
                  values: _audiences,
                  text: _audienceText,
                  onChanged: (v) => setState(() => _audience = v),
                ),
              ),
              AiField(
                label: l.aiGenerateTone,
                child: aiSelect<String>(
                  id: 'dialog.slides.generateDeck.tone',
                  value: _tone,
                  values: _tones,
                  text: _toneText,
                  onChanged: (v) => setState(() => _tone = v),
                ),
              ),
              AiField(
                label: l.aiGenerateLanguage,
                child: aiSelect<String?>(
                  id: 'dialog.slides.generateDeck.language',
                  value: _language,
                  values: _languages,
                  minWidth: 160,
                  text: (v) => v ?? l.aiGenerateLanguageAuto,
                  onChanged: (v) => setState(() => _language = v),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              ShadCheckbox(
                key: const ValueKey<String>('dialog.slides.generateDeck.notes'),
                value: _notes,
                onChanged: (v) => setState(() => _notes = v),
                label: Text(l.aiGenerateNotes),
              ),
              ShadCheckbox(
                key: const ValueKey<String>(
                  'dialog.slides.generateDeck.groups',
                ),
                value: _groups,
                onChanged: (v) => setState(() => _groups = v),
                label: Text(l.aiGenerateGroups),
              ),
              if (outline)
                ShadCheckbox(
                  key: const ValueKey<String>(
                    'dialog.slides.generateDeck.keepWording',
                  ),
                  value: _keepWording,
                  onChanged: (v) => setState(() => _keepWording = v),
                  label: Text(l.aiGenerateKeepWording),
                ),
            ],
          ),
          if (_targets.length > 1)
            AiField(
              label: l.aiGenerateInsert,
              child: aiSelect<GenerateTarget>(
                id: 'dialog.slides.generateDeck.insert',
                value: _target,
                values: _targets,
                minWidth: 200,
                text: _targetText,
                onChanged: (v) => setState(() => _target = v),
              ),
            ),
        ],
      ),
    );
  }

  Widget _outlineEditor(BuildContext context) {
    final theme = ShadTheme.of(context);
    final o = _outline!;
    final rows = <Widget>[];
    var index = 0;
    for (final g in o.groups) {
      if (_groups && g.title != null) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              g.title!,
              style: theme.textTheme.small.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }
      for (final s in g.slides) {
        rows.add(_slideRow(context, index, s, total: o.slideCount));
        index++;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        if (_error != null) AiError(_error!),
        Flexible(child: ListView(shrinkWrap: true, children: rows)),
        Align(
          alignment: Alignment.centerLeft,
          child: ShadButton.ghost(
            key: GenerateDeckKeys.addSlide,
            size: ShadButtonSize.sm,
            leading: const Icon(LucideIcons.plus, size: 14),
            onPressed: _addSlide,
            child: Text(l.aiGenerateAddSlide),
          ),
        ),
      ],
    );
  }

  Widget _slideRow(
    BuildContext context,
    int i,
    AiOutlineSlide s, {
    required int total,
  }) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    if (i >= _fields.length) return const SizedBox.shrink();
    Widget icon(
      ValueKey<String> key,
      IconData data,
      String tip,
      VoidCallback? onPressed,
    ) => ShadTooltip(
      builder: (_) => Text(tip),
      child: ShadIconButton.ghost(
        key: key,
        width: 28,
        height: 28,
        icon: Icon(data, size: 14, semanticLabel: tip),
        onPressed: onPressed,
      ),
    );
    return Container(
      key: ValueKey<String>('dialog.slides.generateDeck.slide.$i'),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: cs.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          Row(
            spacing: 6,
            children: [
              SizedBox(
                width: 24,
                child: Text('${i + 1}', style: theme.textTheme.muted),
              ),
              Expanded(
                child: ShadInput(
                  key: GenerateDeckKeys.slideTitle(i),
                  controller: _fields[i].$1,
                  placeholder: Text(l.aiGenerateSlideTitle),
                ),
              ),
              aiSelect<AiSlideRole>(
                id: 'dialog.slides.generateDeck.slide.$i.role',
                value: s.role,
                values: AiSlideRole.values,
                minWidth: 150,
                text: _roleText,
                onChanged: (r) => _setRole(i, r),
              ),
            ],
          ),
          if (s.role != AiSlideRole.title && s.role != AiSlideRole.section)
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: ShadInput(
                key: GenerateDeckKeys.slideBullets(i),
                controller: _fields[i].$2,
                minLines: 1,
                maxLines: 6,
                placeholder: Text(l.aiGenerateBullets),
              ),
            ),
          if (s.code != null)
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text(
                s.code!,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.muted.copyWith(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              icon(
                ValueKey<String>('dialog.slides.generateDeck.slide.$i.up'),
                LucideIcons.arrowUp,
                l.aiGenerateMoveUp,
                i == 0 ? null : () => _move(i, -1),
              ),
              icon(
                ValueKey<String>('dialog.slides.generateDeck.slide.$i.down'),
                LucideIcons.arrowDown,
                l.aiGenerateMoveDown,
                i == total - 1 ? null : () => _move(i, 1),
              ),
              icon(
                GenerateDeckKeys.regenerateSlide(i),
                LucideIcons.refreshCw,
                l.aiGenerateRegenerateSlide,
                () => unawaited(_regenerateSlide(i)),
              ),
              icon(
                GenerateDeckKeys.deleteSlide(i),
                LucideIcons.trash2,
                l.aiGenerateDeleteSlide,
                () => _deleteSlide(i),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
