import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';

import '../../l10n/wonky_app_localizations.dart';
import '../board_repository.dart';

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
      _set(found.take(maxResults).toList(growable: false));
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

/// The *Similar posts* box of the report dialog: one row per post with its
/// number, title, score and *Vote instead* (keys
/// `dialog.board.report.similar.<number>` and `….vote`).
class BoardSimilarPostsPanel extends StatelessWidget {
  const BoardSimilarPostsPanel({
    super.key,
    required this.posts,
    required this.onVote,
    this.voting,
  });

  final List<BoardSimilarPost> posts;
  final ValueChanged<BoardSimilarPost> onVote;

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
                        child: Text(
                          '#${p.number} ${p.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
