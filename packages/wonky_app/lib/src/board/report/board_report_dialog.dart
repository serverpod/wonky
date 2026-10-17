import 'dart:async';
import 'dart:ui' as ui;

import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' show CommandStatus;

import '../../core/l10n_or_english.dart';
import '../../data/api.dart';
import '../../l10n/wonky_app_localizations.dart';
import '../../markdown/markdown_composer.dart';
import '../../markdown/wonky_markdown.dart';
import '../../mcp_bridge/app_screenshot.dart';
import '../../shell/form_dialog.dart';
import '../../shell/shell_services.dart';
import '../screenshot/screenshot_annotations.dart';
import '../screenshot/screenshot_editor.dart';
import 'board_report_services.dart';
import 'included_details.dart';
import 'report_draft.dart';
import 'similar_posts.dart';

/// Stable keys of the report dialog (specs/16 §4.2).
abstract final class BoardReportKeys {
  static const dialog = 'dialog.board.report';
  static const kindBug = '$dialog.kind.bug';
  static const kindIdea = '$dialog.kind.idea';
  static const addScreenshot = '$dialog.screenshot.add';
  static const editScreenshot = '$dialog.screenshot.edit';
  static const removeScreenshot = '$dialog.screenshot.remove';
  static const thumbnail = '$dialog.screenshot.thumbnail';
  static const captureFailed = '$dialog.screenshot.failed';
  static const screenshotWarning = '$dialog.screenshot.warning';
  static const details = '$dialog.details';
  static const detailsList = '$dialog.details.list';
  static const includeError = '$dialog.includeError';
  static const aiNotice = '$dialog.notice.ai';
  static const securityNotice = '$dialog.notice.security';
  static const blocked = '$dialog.blocked';
  static const error = '$dialog.error';
  static const cancel = '$dialog.cancel';
  static const post = '$dialog.post';

  /// The field of [f] (`dialog.board.report.title`, `….happened`, …); the
  /// long fields are `MarkdownComposer`s with this `fieldKey`.
  static String field(BoardReportField f) => '$dialog.${f.name}';

  /// The validation message under [f].
  static String fieldError(BoardReportField f) => '$dialog.${f.name}.error';
}

/// How the report dialog closed.
enum BoardReportOutcome {
  /// Posted ([BoardReportResult.postNumber]); the draft is cleared.
  posted,

  /// *Vote instead* on a similar post; the draft is kept.
  voted,

  /// Closed and the draft kept (*Keep draft*).
  kept,

  /// Closed and the draft discarded (or there was nothing to keep).
  discarded,
}

/// The result of [showBoardReportDialog].
class BoardReportResult {
  const BoardReportResult(this.outcome, {this.postNumber, this.moderation});

  final BoardReportOutcome outcome;

  /// The new post ([BoardReportOutcome.posted]).
  final int? postNumber;
  final BoardModeration? moderation;
}

/// The board security contact when `board.me` hasn't answered (B14).
const _defaultSecurityContact = 'security@serverpod.dev';

/// Opens the report dialog (specs/16 §4.2; `dialog.board.report`, width
/// 640, full screen below 600 px) with the saved draft of this app, set to
/// [kind] when given. [screenshot] is the capture taken before the dialog
/// opened (§5.1), disposed when the dialog closes; [screenshotFailed]
/// shows *Couldn't capture the screen* instead of *Add screenshot*.
/// [includeLastError] ticks *Include the last error* (the error card's
/// *Report this bug*).
///
/// *See all posts* navigates to `/improvements` after closing; a posted
/// report toasts *Posted. Checking it now…* with *View*.
Future<BoardReportResult?> showBoardReportDialog(
  BuildContext context,
  ShellServices s, {
  BoardPostKind? kind,
  ui.Image? screenshot,
  bool screenshotFailed = false,
  bool includeLastError = false,
}) async {
  final store = BoardReportDraftStore(s.userStore, s.config.app);
  final saved = await store.load();
  if (!context.mounted) {
    screenshot?.dispose();
    return null;
  }
  final initial = (saved ?? const BoardReportDraft()).copyWith(
    kind: kind,
    includeError: includeLastError ? true : null,
  );
  final result = await showShadDialog<BoardReportResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BoardReportDialog(
      services: s,
      store: store,
      initial: initial,
      screenshot: screenshot,
      screenshotFailed: screenshotFailed || screenshot == null,
    ),
  );
  return result;
}

class BoardReportDialog extends StatefulWidget {
  const BoardReportDialog({
    super.key,
    required this.services,
    required this.store,
    required this.initial,
    this.screenshot,
    this.screenshotFailed = false,
  });

  final ShellServices services;
  final BoardReportDraftStore store;
  final BoardReportDraft initial;

  /// Owned by the dialog (disposed on close).
  final ui.Image? screenshot;
  final bool screenshotFailed;

  @override
  State<BoardReportDialog> createState() => BoardReportDialogState();
}

class BoardReportDialogState extends State<BoardReportDialog>
    with McpDialogRegistration<BoardReportDialog> {
  ShellServices get s => widget.services;
  BoardReportServices get _rs => BoardReportServices.of(s);

  late BoardPostKind _kind = widget.initial.kind;
  late final Map<BoardReportField, TextEditingController> _text = {
    for (final f in BoardReportField.values)
      f: TextEditingController(text: widget.initial[f]),
  };
  late bool? _includeError = widget.initial.includeError;
  late final BoardSimilarSearch _similar = BoardSimilarSearch(
    repository: s.repositories.board,
    debounce: _rs.similarDebounce,
  );
  Map<BoardReportField, BoardReportProblem> _problems = const {};
  BoardMe? _me;
  AnnotatedScreenshot? _shot;
  (EncodedScreenshot, UuidValue)? _uploaded;
  bool _detailsOpen = false;
  bool _detailsFocused = false;
  bool _posting = false;
  int? _voting;
  String? _error;

  /// The current draft.
  BoardReportDraft get draft => BoardReportDraft(
    kind: _kind,
    text: {for (final e in _text.entries) e.key: e.value.text},
    includeError: _includeError,
  );

  /// The annotated screenshot after the editor's *Done* (null: none).
  AnnotatedScreenshot? get screenshot => _shot;

  @override
  void initState() {
    super.initState();
    for (final c in _text.values) {
      c.addListener(_onText);
    }
    _searchSimilar();
    unawaited(_loadMe());
  }

  Future<void> _loadMe() async {
    try {
      final me = await s.repositories.board.me();
      if (mounted) setState(() => _me = me);
    } catch (_) {
      // The notices fall back to the defaults.
    }
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    _similar.dispose();
    widget.screenshot?.dispose();
    super.dispose();
  }

  void _onText() {
    _searchSimilar();
    if (_problems.isNotEmpty) {
      final next = validateBoardReport(draft);
      final shown = {
        for (final e in next.entries)
          if (_problems.containsKey(e.key)) e.key: e.value,
      };
      if (shown.length != _problems.length) setState(() => _problems = shown);
    }
    unawaited(widget.store.save(draft));
  }

  void _searchSimilar() => _similar.update(
    _text[BoardReportField.title]!.text,
    buildBoardReportBody(_kind, {
      for (final f in BoardReportField.bodyFields(_kind)) f: _text[f]!.text,
    }),
    _kind,
  );

  void setKind(BoardPostKind kind) {
    if (kind == _kind) return;
    setState(() {
      _kind = kind;
      _problems = const {};
      _error = null;
    });
    _searchSimilar();
    unawaited(widget.store.save(draft));
  }

  // ---- Last error ----

  BoardLastError? get _lastError => _rs.lastError.value;

  bool get _errorIncluded {
    final e = _lastError;
    if (e == null || _kind != BoardPostKind.bug) return false;
    return _includeError ??
        clock.now().difference(e.at) < BoardReportServices.recentError;
  }

  String _errorAge(WonkyAppLocalizations l, DateTime at) {
    final minutes = clock.now().difference(at).inMinutes;
    return minutes >= 60
        ? l.boardReportErrorAgeHours(minutes ~/ 60)
        : l.boardReportErrorAge(minutes);
  }

  // ---- Closing ----

  /// *Cancel*, ✕ and `Esc`: asks *Discard draft?* when there is content
  /// (*Keep draft* closes and keeps it, *Discard* clears it, `Esc` goes
  /// back to the dialog).
  Future<void> requestClose() async {
    if (_posting) return;
    if (!draft.hasContent) {
      await widget.store.clear();
      if (mounted) {
        Navigator.of(
          context,
        ).pop(const BoardReportResult(BoardReportOutcome.discarded));
      }
      return;
    }
    final l = WonkyAppLocalizations.of(context);
    final r = await showWonkyFormDialog(
      context,
      WonkyDialogSpec(
        title: l.boardReportDiscardTitle,
        description: l.boardReportDiscardBody,
        dialogKey: 'dialog.board.discardDraft',
        width: 420,
        buttons: [
          DialogButtonSpec(id: 'keep', label: l.boardReportKeepDraft),
          DialogButtonSpec(
            id: 'discard',
            label: l.boardReportDiscard,
            primary: true,
            destructive: true,
          ),
        ],
      ),
    );
    if (!mounted) return;
    switch (r?.buttonId) {
      case 'discard':
        await widget.store.clear();
        if (mounted) {
          Navigator.of(
            context,
          ).pop(const BoardReportResult(BoardReportOutcome.discarded));
        }
      case 'keep':
        await widget.store.save(draft);
        if (mounted) {
          Navigator.of(
            context,
          ).pop(const BoardReportResult(BoardReportOutcome.kept));
        }
    }
  }

  // ---- Screenshot ----

  Future<void> editScreenshot() async {
    final image = widget.screenshot;
    if (image == null || _posting) return;
    final r = await showScreenshotEditor(
      context,
      image,
      initial: _shot?.annotations ?? const [],
      finish: _rs.finish,
    );
    if (r != null && mounted) setState(() => _shot = r);
  }

  void removeScreenshot() => setState(() => _shot = null);

  // ---- Vote instead ----

  Future<void> voteInstead(BoardSimilarPost p) async {
    if (_voting != null || _posting) return;
    final l = WonkyAppLocalizations.of(context);
    setState(() {
      _voting = p.number;
      _error = null;
    });
    try {
      if (s.registry.byId('shell.board.vote') != null) {
        final r = await s.dispatcher.invoke(
          'shell.board.vote',
          args: {'postNumber': p.number, 'value': 1},
          context: context,
        );
        // Cancelled: the vote was already there.
        if (r.status == CommandStatus.failed) {
          throw StateError(r.message ?? r.status.name);
        }
      } else {
        await s.repositories.board.vote(p.number, 1);
      }
      await widget.store.save(draft);
      if (!mounted) return;
      Navigator.of(
        context,
      ).pop(const BoardReportResult(BoardReportOutcome.voted));
      s.toasts.show(
        p.kind == BoardPostKind.bug
            ? l.boardReportHitThisToo(p.number)
            : l.boardReportVotedFor(p.number),
        actionLabel: l.boardReportView,
        onAction: () => s.router.go('/improvements/p/${p.number}'),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _voting = null;
        _error = l.boardReportVoteFailed(errorMessage(e));
      });
    }
  }

  // ---- Posting ----

  BoardIncludedDetails _details(BuildContext context) =>
      BoardIncludedDetails.collect(s, context);

  Future<void> post() async {
    if (_posting || _voting != null) return;
    final l = WonkyAppLocalizations.of(context);
    final d = draft;
    final problems = validateBoardReport(d);
    setState(() {
      _problems = problems;
      _error = null;
    });
    if (problems.isNotEmpty || _me?.blocked == true) return;
    final contextJson = d.kind == BoardPostKind.bug
        ? _details(context).encode(error: _errorIncluded ? _lastError : null)
        : null;
    setState(() => _posting = true);
    try {
      UuidValue? shotUuid;
      final shot = _shot;
      if (shot != null) {
        final done = _uploaded;
        if (done != null && identical(done.$1, shot.encoded)) {
          shotUuid = done.$2;
        } else {
          try {
            shotUuid = await _rs.uploadScreenshot(shot.encoded);
          } catch (e) {
            throw _UploadFailed(e);
          }
          _uploaded = (shot.encoded, shotUuid);
        }
      }
      if (!mounted) return;
      // `shell.board.createPost`: undoable, and open board pages refresh.
      final r = await s.dispatcher.invoke(
        'shell.board.createPost',
        args: {
          'kind': d.kind.name,
          'title': d[BoardReportField.title].trim(),
          'body': d.body,
          'contextJson': ?contextJson,
          'appHint': s.config.app.name,
          'screenshotFileUuid': ?shotUuid?.uuid,
        },
        context: context,
      );
      final data = r.data;
      if (!r.isOk || data is! Map) {
        throw StateError(r.message ?? r.status.name);
      }
      final number = data['postNumber'] as int;
      final moderation = BoardModeration.values.byName(
        data['moderation'] as String,
      );
      await widget.store.clear();
      if (!mounted) return;
      Navigator.of(context).pop(
        BoardReportResult(
          BoardReportOutcome.posted,
          postNumber: number,
          moderation: moderation,
        ),
      );
      s.toasts.show(
        switch (moderation) {
          BoardModeration.visible => l.boardReportPosted,
          BoardModeration.held => l.boardReportPostedHeld,
          _ => l.boardReportPostedChecking,
        },
        actionLabel: l.boardReportView,
        onAction: () => s.router.go('/improvements/p/$number'),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _posting = false;
        _error = _describeError(l, e);
      });
    }
  }

  String _describeError(WonkyAppLocalizations l, Object e) {
    if (e is _UploadFailed) {
      return l.boardReportUploadFailed(errorMessage(e.cause));
    }
    if (e is WonkyException) {
      switch (e.code) {
        case WonkyErrorCode.limitExceeded:
          return l.boardReportRateLimited;
        case WonkyErrorCode.forbidden:
          return l.boardReportBlocked;
        default:
          return l.boardReportPostFailed(e.message);
      }
    }
    return l.boardReportPostFailed(errorMessage(e));
  }

  // ---- MCP (`ui.get_dialog`) ----

  @override
  Map<String, Object?> describe() {
    final l = wonkyAppL10nOrEnglish(context);
    return {
      'title': l.boardReportName,
      'kind': 'boardReport',
      'fields': [
        {
          'id': 'kind',
          'label': l.boardReportKindLabel,
          'type': 'select',
          'value': _kind.name,
          'options': [for (final k in BoardPostKind.values) k.name],
        },
        for (final f in [
          BoardReportField.title,
          ...BoardReportField.bodyFields(_kind),
        ])
          {
            'id': f.name,
            'label': _label(l, f),
            'type': 'text',
            'value': _text[f]!.text,
            if (_problems[f] != null)
              'error': _problemText(l, f, _problems[f]!),
          },
        if (_lastError != null && _kind == BoardPostKind.bug)
          {
            'id': 'includeError',
            'label': l.boardReportIncludeError(_errorAge(l, _lastError!.at)),
            'type': 'checkbox',
            'value': _errorIncluded,
          },
      ],
      'screenshot': _shot != null
          ? 'added'
          : (widget.screenshot == null ? 'unavailable' : 'none'),
      'similar': [
        for (final p in _similar.results)
          {'number': p.number, 'title': p.title, 'score': p.score},
      ],
      'error': ?_error,
      'buttons': [
        {'id': 'cancel', 'label': l.actionCancel},
        {'id': 'post', 'label': _postLabel(l)},
      ],
    };
  }

  @override
  bool setField(String id, Object? value) {
    if (id == 'kind') {
      final k = BoardPostKind.values.where((k) => k.name == value);
      if (k.isEmpty) return false;
      setKind(k.first);
      return true;
    }
    if (id == 'includeError') {
      if (value is! bool) return false;
      setState(() => _includeError = value);
      unawaited(widget.store.save(draft));
      return true;
    }
    final f = BoardReportField.values.where((f) => f.name == id);
    if (f.isEmpty) return false;
    _text[f.first]!.text = '${value ?? ''}';
    return true;
  }

  @override
  bool press(String buttonId) {
    switch (buttonId) {
      case 'post':
        post();
      case 'cancel' || 'close':
        requestClose();
      default:
        return false;
    }
    return true;
  }

  // ---- UI ----

  String _postLabel(WonkyAppLocalizations l) =>
      _kind == BoardPostKind.bug ? l.boardReportPostBug : l.boardReportPostIdea;

  String _label(WonkyAppLocalizations l, BoardReportField f) => switch (f) {
    BoardReportField.title => l.boardReportFieldTitle,
    BoardReportField.happened => l.boardReportFieldHappened,
    BoardReportField.expected => l.boardReportFieldExpected,
    BoardReportField.steps => l.boardReportFieldSteps,
    BoardReportField.idea => l.boardReportFieldIdea,
    BoardReportField.why => l.boardReportFieldWhy,
  };

  String _problemText(
    WonkyAppLocalizations l,
    BoardReportField f,
    BoardReportProblem p,
  ) => switch (p) {
    BoardReportProblem.titleLength => l.boardReportTitleLength(
      BoardReportLimits.titleMin,
      BoardReportLimits.titleMax,
    ),
    BoardReportProblem.required => l.errorRequired,
    BoardReportProblem.bodyTooLong => l.boardReportBodyTooLong(
      BoardReportLimits.bodyMax,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final narrow = size.width < 600;
    // The surface of `ShadDialog` (the popover color, the dialog border,
    // radius and shadow of the theme); full screen below 600 px.
    final dialogTheme = theme.primaryDialogTheme;
    final panel = Container(
      key: const ValueKey<String>(BoardReportKeys.dialog),
      width: narrow ? size.width : 640,
      height: narrow ? size.height : null,
      constraints: BoxConstraints(
        maxHeight: narrow ? size.height : size.height - 48,
      ),
      decoration: BoxDecoration(
        color: dialogTheme.backgroundColor ?? cs.popover,
        border: narrow
            ? null
            : (dialogTheme.border ?? Border.all(color: cs.border)),
        borderRadius: narrow ? null : (dialogTheme.radius ?? theme.radius),
        boxShadow: narrow ? null : dialogTheme.shadows,
      ),
      clipBehavior: narrow ? Clip.none : Clip.antiAlias,
      child: SafeArea(
        top: narrow,
        bottom: narrow,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(l, theme),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: _body(l, theme),
                ),
              ),
            ),
            _footer(l, theme),
          ],
        ),
      ),
    );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) requestClose();
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): requestClose,
        },
        child: FocusScope(
          autofocus: true,
          child: Semantics(
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: l.boardReportName,
            child: narrow ? panel : Center(child: panel),
          ),
        ),
      ),
    );
  }

  Widget _header(WonkyAppLocalizations l, ShadThemeData theme) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              l.boardReportName,
              style:
                  theme.primaryDialogTheme.titleStyle ?? theme.textTheme.large,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    ),
  );

  List<Widget> _body(WonkyAppLocalizations l, ShadThemeData theme) {
    final cs = theme.colorScheme;
    final small = theme.textTheme.small;
    final muted = theme.textTheme.muted.copyWith(fontSize: 13);
    Widget kindButton(String key, BoardPostKind k, IconData icon, String t) {
      final selected = _kind == k;
      return Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: (selected ? ShadButton.secondary : ShadButton.ghost)(
          key: ValueKey<String>(key),
          size: ShadButtonSize.sm,
          leading: Icon(icon, size: 14),
          onPressed: _posting ? null : () => setKind(k),
          child: Flexible(
            child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      );
    }

    Widget problem(BoardReportField f) {
      final p = _problems[f];
      if (p == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          _problemText(l, f, p),
          key: ValueKey<String>(BoardReportKeys.fieldError(f)),
          style: small.copyWith(color: cs.destructive),
        ),
      );
    }

    Widget label(BoardReportField f) {
      final optional =
          f != BoardReportField.title &&
          f != BoardReportField.requiredField(_kind);
      return Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text.rich(
          TextSpan(
            text: _label(l, f),
            children: [
              if (optional)
                TextSpan(
                  text: ' ${l.boardReportOptional}',
                  style: TextStyle(color: cs.mutedForeground),
                ),
            ],
          ),
          style: small,
        ),
      );
    }

    final bug = _kind == BoardPostKind.bug;
    return [
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          kindButton(
            BoardReportKeys.kindBug,
            BoardPostKind.bug,
            LucideIcons.bug,
            l.boardReportKindBug,
          ),
          kindButton(
            BoardReportKeys.kindIdea,
            BoardPostKind.idea,
            LucideIcons.leaf,
            l.boardReportKindIdea,
          ),
        ],
      ),
      label(BoardReportField.title),
      ShadInput(
        key: ValueKey<String>(BoardReportKeys.field(BoardReportField.title)),
        controller: _text[BoardReportField.title],
        autofocus: true,
        maxLength: BoardReportLimits.titleMax,
        enabled: !_posting,
        placeholder: Text(
          bug ? l.boardReportTitleHintBug : l.boardReportTitleHintIdea,
        ),
      ),
      problem(BoardReportField.title),
      ListenableBuilder(
        listenable: _similar,
        builder: (context, _) => _similar.results.isEmpty
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(top: 10),
                child: BoardSimilarPostsPanel(
                  posts: _similar.results,
                  voting: _voting,
                  onVote: voteInstead,
                ),
              ),
      ),
      for (final f in BoardReportField.bodyFields(_kind)) ...[
        label(f),
        MarkdownComposer(
          key: ValueKey<String>('${BoardReportKeys.field(f)}.composer'),
          controller: _text[f],
          fieldKey: BoardReportKeys.field(f),
          profile: MarkdownProfile.post,
          hint: f == BoardReportField.steps ? '1. ' : null,
          minLines: f == BoardReportField.requiredField(_kind) ? 4 : 3,
          maxLines: 10,
          maxLength: BoardReportLimits.bodyMax,
          enabled: !_posting,
          onSubmit: post,
        ),
        problem(f),
      ],
      const SizedBox(height: 16),
      _screenshotSection(l, theme),
      if (bug) ...[const SizedBox(height: 14), _detailsSection(l, theme)],
      const SizedBox(height: 16),
      Text(
        _me?.aiChecks == true
            ? l.boardReportAiNotice
            : l.boardReportPublicNotice,
        key: const ValueKey<String>(BoardReportKeys.aiNotice),
        style: muted,
      ),
      const SizedBox(height: 2),
      Text(
        l.boardReportSecurityNotice(
          _me?.securityContact ?? _defaultSecurityContact,
        ),
        key: const ValueKey<String>(BoardReportKeys.securityNotice),
        style: muted,
      ),
      if (_me?.blocked == true) ...[
        const SizedBox(height: 10),
        Text(
          _me?.blockedReason == null
              ? l.boardReportBlocked
              : l.boardReportBlockedReason(_me!.blockedReason!),
          key: const ValueKey<String>(BoardReportKeys.blocked),
          style: small.copyWith(color: cs.destructive),
        ),
      ],
      if (_error != null) ...[
        const SizedBox(height: 10),
        Semantics(
          liveRegion: true,
          child: Text(
            _error!,
            key: const ValueKey<String>(BoardReportKeys.error),
            style: small.copyWith(color: cs.destructive),
          ),
        ),
      ],
    ];
  }

  Widget _screenshotSection(WonkyAppLocalizations l, ShadThemeData theme) {
    final cs = theme.colorScheme;
    final small = theme.textTheme.small;
    final image = widget.screenshot;
    if (widget.screenshotFailed || image == null) {
      return Row(
        children: [
          Text(l.boardReportScreenshot, style: small),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l.boardReportCaptureFailed,
              key: const ValueKey<String>(BoardReportKeys.captureFailed),
              style: theme.textTheme.muted,
            ),
          ),
        ],
      );
    }
    final shot = _shot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l.boardReportScreenshot, style: small),
            if (shot == null)
              ShadButton.outline(
                key: const ValueKey<String>(BoardReportKeys.addScreenshot),
                size: ShadButtonSize.sm,
                leading: const Icon(LucideIcons.imagePlus, size: 14),
                onPressed: _posting ? null : editScreenshot,
                child: Text(l.boardReportAddScreenshot),
              )
            else ...[
              Semantics(
                image: true,
                label: l.boardReportScreenshotPreview,
                child: GestureDetector(
                  onTap: _posting ? null : editScreenshot,
                  child: Container(
                    key: const ValueKey<String>(BoardReportKeys.thumbnail),
                    width: 160,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: cs.border),
                      borderRadius: theme.radius,
                      color: cs.muted,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CustomPaint(
                      painter: _ThumbnailPainter(image, shot.annotations),
                    ),
                  ),
                ),
              ),
              ShadButton.link(
                key: const ValueKey<String>(BoardReportKeys.editScreenshot),
                size: ShadButtonSize.sm,
                onPressed: _posting ? null : editScreenshot,
                child: Text(l.boardReportEditScreenshot),
              ),
              ShadButton.link(
                key: const ValueKey<String>(BoardReportKeys.removeScreenshot),
                size: ShadButtonSize.sm,
                onPressed: _posting ? null : removeScreenshot,
                child: Text(l.boardReportRemoveScreenshot),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 6),
              child: Icon(
                LucideIcons.triangleAlert,
                size: 14,
                color: cs.mutedForeground,
              ),
            ),
            Expanded(
              child: Text(
                l.boardReportScreenshotWarning,
                key: const ValueKey<String>(BoardReportKeys.screenshotWarning),
                style: theme.textTheme.muted.copyWith(fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _detailsSection(WonkyAppLocalizations l, ShadThemeData theme) {
    final cs = theme.colorScheme;
    final details = _details(context);
    final themeLabel = details.dark
        ? l.boardReportThemeDark
        : l.boardReportThemeLight;
    final summary = details.summary(themeLabel);
    final error = _lastError;
    final muted = theme.textTheme.muted.copyWith(fontSize: 13);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          expanded: _detailsOpen,
          child: FocusableActionDetector(
            mouseCursor: SystemMouseCursors.click,
            onShowFocusHighlight: (v) => setState(() => _detailsFocused = v),
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  setState(() => _detailsOpen = !_detailsOpen);
                  return null;
                },
              ),
            },
            child: GestureDetector(
              key: const ValueKey<String>(BoardReportKeys.details),
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _detailsOpen = !_detailsOpen),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _detailsFocused ? cs.ring : const Color(0x00000000),
                  ),
                  borderRadius: theme.radius,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2, right: 4),
                      child: Icon(
                        _detailsOpen
                            ? LucideIcons.chevronDown
                            : LucideIcons.chevronRight,
                        size: 14,
                        color: cs.mutedForeground,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        l.boardReportDetails(summary),
                        style: muted,
                        maxLines: _detailsOpen ? null : 2,
                        overflow: _detailsOpen ? null : TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_detailsOpen)
          Padding(
            key: const ValueKey<String>(BoardReportKeys.detailsList),
            padding: const EdgeInsets.fromLTRB(18, 6, 0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (k, v) in [
                  (
                    l.boardReportDetailApp,
                    '${details.app.shortName} ${details.version}',
                  ),
                  (
                    l.boardReportDetailPlatform,
                    [details.platform, ?details.browser].join(' · '),
                  ),
                  (l.boardReportDetailTheme, themeLabel),
                  (l.boardReportDetailLocale, details.locale),
                  (l.boardReportDetailWindow, details.window),
                  (l.boardReportDetailRoute, details.route),
                  if (_errorIncluded && error != null)
                    (l.boardReportDetailError, error.message.split('\n').first),
                ])
                  Text('$k: $v', style: muted),
              ],
            ),
          ),
        if (error != null) ...[
          const SizedBox(height: 8),
          ShadCheckbox(
            key: const ValueKey<String>(BoardReportKeys.includeError),
            value: _errorIncluded,
            enabled: !_posting,
            onChanged: (v) {
              setState(() => _includeError = v);
              unawaited(widget.store.save(draft));
            },
            label: Text(l.boardReportIncludeError(_errorAge(l, error.at))),
          ),
        ],
      ],
    );
  }

  /// The actions as in `ShadDialog` / `WonkyFormDialog`: Cancel, then the
  /// primary at the end; below shad's `sm` breakpoint (640 px) they stack,
  /// full width, the primary on top.
  Widget _footer(WonkyAppLocalizations l, ShadThemeData theme) {
    final cancel = ShadButton.outline(
      key: const ValueKey<String>(BoardReportKeys.cancel),
      width: _stackedActions ? double.infinity : null,
      onPressed: _posting ? null : requestClose,
      child: Text(l.actionCancel),
    );
    final postButton = ShadButton(
      key: const ValueKey<String>(BoardReportKeys.post),
      width: _stackedActions ? double.infinity : null,
      onPressed: _posting || _me?.blocked == true ? null : post,
      leading: _posting
          ? const SizedBox.square(dimension: 14, child: ShadSpinner())
          : null,
      child: Flexible(
        child: Text(
          _postLabel(l),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: _stackedActions
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [postButton, cancel],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                cancel,
                Flexible(child: postButton),
              ],
            ),
    );
  }

  bool get _stackedActions => MediaQuery.sizeOf(context).width < 640;
}

class _UploadFailed implements Exception {
  const _UploadFailed(this.cause);

  final Object cause;
}

/// The dialog's thumbnail: the capture with its annotations, fit to the
/// box.
class _ThumbnailPainter extends CustomPainter {
  _ThumbnailPainter(this.image, this.annotations);

  final ui.Image image;
  final List<ScreenshotAnnotation> annotations;

  @override
  void paint(Canvas canvas, Size size) {
    final src = Size(image.width.toDouble(), image.height.toDouble());
    final scale = [
      size.width / src.width,
      size.height / src.height,
    ].reduce((a, b) => a < b ? a : b);
    final w = src.width * scale, h = src.height * scale;
    final dx = (size.width - w) / 2, dy = (size.height - h) / 2;
    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);
    canvas.drawImage(
      image,
      Offset.zero,
      Paint()..filterQuality = FilterQuality.medium,
    );
    paintScreenshotAnnotations(canvas, annotations, src);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ThumbnailPainter old) =>
      old.image != image || !identical(old.annotations, annotations);
}
