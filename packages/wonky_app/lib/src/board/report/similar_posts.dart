import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../../l10n/wonky_app_localizations.dart';
import '../../markdown/wonky_markdown.dart';
import '../board_repository.dart';
import '../pages/board_labels.dart';
import '../pages/board_widgets.dart';

/// Finds similar posts while the user types (specs/16 §4.2.2): debounced
/// [debounce] after the title or body changes, at least [minWords] words,
/// up to 5 visible posts from `board.similar`. Stale answers are dropped;
/// failures show nothing.
class BoardSimilarSearch extends ChangeNotifier {
  BoardSimilarSearch({
    required this.repository,
    this.debounce = const Duration(milliseconds: 400),
  });

  static const minWords = 3;
  static const maxResults = 5;
  static const _suggested = {BoardPostStatus.open, BoardPostStatus.planned};

  final BoardRepository repository;
  final Duration debounce;

  Timer? _timer;
  int _generation = 0;
  String _query = '';
  List<BoardSimilarPost> _results = const [];
  bool _disposed = false;

  List<BoardSimilarPost> get results => _results;

  /// The text changed: searches again after [debounce].
  void update(String title, String body, BoardPostKind kind) {
    final query = '${title.trim()}\n${body.trim()}|${kind.name}';
    if (query == _query) return;
    _query = query;
    _timer?.cancel();
    final generation = ++_generation;
    final words = '$title $body'
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    if (words < minWords) {
      _set(const []);
      return;
    }
    _timer = Timer(debounce, () async {
      List<BoardSimilarPost> found;
      try {
        found = await repository.similar(title.trim(), body.trim(), kind);
      } catch (_) {
        found = const [];
      }
      if (_disposed || generation != _generation) return;
      // Built issues are not suggested: done and shipped ones can't be
      // voted for (older servers still return done ones).
      _set(
        found
            .where((p) => _suggested.contains(p.status))
            .take(maxResults)
            .toList(growable: false),
      );
    });
  }

  /// Marks [number] as voted (after *Vote instead*).
  void markVoted(int number, {int? score}) => _set([
    for (final p in _results)
      p.number == number ? p.copyWith(myVote: 1, score: score ?? p.score) : p,
  ]);

  void _set(List<BoardSimilarPost> r) {
    if (_disposed) return;
    if (r.isEmpty && _results.isEmpty) return;
    _results = r;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

/// The *Similar issues* box of the report dialog: one row per post with its
/// number and title (a link that opens [onOpen], the post's details), its
/// score and *Vote instead* (keys `dialog.board.report.similar.<number>`,
/// `….open` and `….vote`).
class BoardSimilarPostsPanel extends StatelessWidget {
  const BoardSimilarPostsPanel({
    super.key,
    required this.posts,
    required this.onVote,
    this.onOpen,
    this.voting,
  });

  final List<BoardSimilarPost> posts;
  final ValueChanged<BoardSimilarPost> onVote;

  /// Shows the details of a post (the title link); null: plain titles.
  final ValueChanged<BoardSimilarPost>? onOpen;

  /// The post being voted for (its button is busy).
  final int? voting;

  static const keyPrefix = 'dialog.board.report.similar';

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) return const SizedBox.shrink();
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    return Semantics(
      container: true,
      label: l.boardReportSimilarTitle,
      child: DecoratedBox(
        key: const ValueKey<String>(keyPrefix),
        decoration: BoxDecoration(
          border: Border.all(color: cs.border),
          borderRadius: theme.radius,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.boardReportSimilarTitle, style: theme.textTheme.small),
              const SizedBox(height: 4),
              for (final p in posts)
                Padding(
                  key: ValueKey<String>('$keyPrefix.${p.number}'),
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        p.kind == BoardPostKind.bug
                            ? LucideIcons.bug
                            : LucideIcons.leaf,
                        size: 14,
                        color: cs.mutedForeground,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: onOpen == null
                            ? Text(
                                '#${p.number} ${p.title}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : _TitleLink(
                                key: ValueKey<String>(
                                  '$keyPrefix.${p.number}.open',
                                ),
                                text: '#${p.number} ${p.title}',
                                semanticsLabel: l.boardSimilarShow(
                                  p.number,
                                  p.title,
                                ),
                                onTap: () => onOpen!(p),
                              ),
                      ),
                      const SizedBox(width: 8),
                      Semantics(
                        label: l.boardReportSimilarVotes(p.score),
                        excludeSemantics: true,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.chevronUp,
                              size: 14,
                              color: cs.mutedForeground,
                            ),
                            Text('${p.score}', style: theme.textTheme.muted),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ShadButton.outline(
                        key: ValueKey<String>('$keyPrefix.${p.number}.vote'),
                        size: ShadButtonSize.sm,
                        enabled: p.myVote <= 0 && voting == null,
                        onPressed: () => onVote(p),
                        child: Text(
                          p.myVote > 0
                              ? l.boardReportVoted
                              : l.boardReportVoteInstead,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A one-line title that opens something: underlined on hover, the focus
/// ring, Enter / Space.
class _TitleLink extends StatefulWidget {
  const _TitleLink({
    super.key,
    required this.text,
    required this.semanticsLabel,
    required this.onTap,
  });

  final String text;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  State<_TitleLink> createState() => _TitleLinkState();
}

class _TitleLinkState extends State<_TitleLink> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _focus ? cs.ring : const Color(0x00000000),
              ),
            ),
            child: Text(
              widget.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cs.foreground,
                decoration: _hover ? TextDecoration.underline : null,
                decorationColor: cs.foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The details of a similar post over the report dialog (specs/16 §4.2.2):
/// its number and title, labels, status and score, the author and the
/// Markdown body, read with `board.getPost`. Resolves with true when the
/// user chose *Vote instead* (the report dialog then votes), else null.
/// Key `dialog.board.similarPost` (`….vote`, `….close`, `….body`).
Future<bool?> showBoardSimilarPostDialog(
  BuildContext context, {
  required BoardRepository repository,
  required BoardSimilarPost post,
  bool canVote = true,
}) => showShadDialog<bool>(
  context: context,
  builder: (_) =>
      _SimilarPostDialog(repository: repository, post: post, canVote: canVote),
);

class _SimilarPostDialog extends StatefulWidget {
  const _SimilarPostDialog({
    required this.repository,
    required this.post,
    required this.canVote,
  });

  final BoardRepository repository;
  final BoardSimilarPost post;
  final bool canVote;

  @override
  State<_SimilarPostDialog> createState() => _SimilarPostDialogState();
}

class _SimilarPostDialogState extends State<_SimilarPostDialog> {
  late final Future<BoardPostView> _view = widget.repository.getPost(
    widget.post.number,
  );

  static const _key = 'dialog.board.similarPost';

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final size = MediaQuery.sizeOf(context);
    final p = widget.post;
    final voted = p.myVote > 0;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
      },
      child: ShadDialog(
        key: const ValueKey<String>(_key),
        closeIcon: const WonkyDialogCloseButton(),
        constraints: const BoxConstraints(maxWidth: 640),
        title: BoardNumberedTitle(
          number: '#${p.number}',
          title: p.title,
          style: theme.textTheme.large,
          maxLines: 3,
        ),
        actions: [
          ShadButton.outline(
            key: const ValueKey<String>('$_key.close'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.actionClose),
          ),
          ShadButton(
            key: const ValueKey<String>('$_key.vote'),
            enabled: widget.canVote && !voted,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(voted ? l.boardReportVoted : l.boardReportVoteInstead),
          ),
        ],
        child: SizedBox(
          width: size.width < 680 ? size.width - 48 : 592,
          child: FutureBuilder<BoardPostView>(
            future: _view,
            builder: (context, snap) {
              final v = snap.data;
              final muted = theme.textTheme.muted.copyWith(fontSize: 12);
              final chips = Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ...boardLabelChips(
                    l,
                    kind: p.kind,
                    area: v?.area,
                    size: v?.size,
                    ai: v?.aiLabels ?? false,
                  ),
                  BoardStatusBadge(
                    status: p.status,
                    label: l.boardStatusName(p.status),
                  ),
                  Text(l.boardReportSimilarVotes(p.score), style: muted),
                ],
              );
              final Widget body;
              if (snap.hasError) {
                body = Text(
                  l.boardSimilarLoadFailed,
                  key: const ValueKey<String>('$_key.error'),
                  style: theme.textTheme.muted,
                );
              } else if (v == null) {
                body = const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: ShadSpinner()),
                );
              } else {
                body = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 12,
                  children: [
                    BoardAuthorLine(
                      author: v.author,
                      createdAt: v.createdAt,
                      editedAt: v.editedAt,
                    ),
                    WonkyMarkdown(
                      v.body,
                      key: const ValueKey<String>('$_key.body'),
                      profile: MarkdownProfile.post,
                    ),
                  ],
                );
              }
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: (size.height * 0.6).clamp(200, 480).toDouble(),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 14,
                    children: [chips, body],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
