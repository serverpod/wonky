import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../l10n/write_l10n.dart';
import 'write_ai_controller.dart';

enum ProofreadIssueStatus { open, accepted, dismissed, stale }

/// One issue in the list.
class ProofreadIssueState {
  ProofreadIssueState(this.issue);
  final ProofreadIssue issue;
  ProofreadIssueStatus status = ProofreadIssueStatus.open;
}

/// Proofreading results (Write 09 §5.5): issues grouped by category with
/// Accept (one undo step each), Dismiss, Accept all in category and Accept
/// all (one step). Issues are re-resolved by quote when accepted; issues
/// whose text changed are greyed ("Text changed").
class ProofreadResults extends ChangeNotifier {
  ProofreadResults(this.ai);

  final WriteAiController ai;
  final List<ProofreadIssueState> issues = [];
  int sectionsDone = 0;
  int sectionsTotal = 0;
  bool finished = false;
  String? error;

  static const categories = [
    'spelling',
    'grammar',
    'punctuation',
    'style',
    'clarity',
  ];

  static String categoryLabel(WriteLocalizations l, String c) => switch (c) {
    'spelling' => l.proofreadCategorySpelling,
    'grammar' => l.proofreadCategoryGrammar,
    'punctuation' => l.proofreadCategoryPunctuation,
    'style' => l.proofreadCategoryStyle,
    _ => l.proofreadCategoryClarity,
  };

  void onEvent(ProofreadEvent e) {
    switch (e.type) {
      case 'issues':
        issues.addAll([
          for (final i in e.issues ?? const <ProofreadIssue>[])
            ProofreadIssueState(i),
        ]);
        sectionsDone = e.sectionsDone ?? sectionsDone;
        sectionsTotal = e.sectionsTotal ?? sectionsTotal;
      case 'progress':
        sectionsDone = e.sectionsDone ?? sectionsDone;
        sectionsTotal = e.sectionsTotal ?? sectionsTotal;
      case 'error' || 'refusal':
        error = e.error;
      case 'done':
        finished = true;
    }
    notifyListeners();
  }

  void fail(String message) {
    error = message;
    notifyListeners();
  }

  void finish() {
    finished = true;
    _revalidate();
    notifyListeners();
  }

  List<ProofreadIssueState> inCategory(String c) => [
    for (final i in issues)
      if (i.issue.category == c) i,
  ];

  List<ProofreadIssueState> get open => [
    for (final i in issues)
      if (i.status == ProofreadIssueStatus.open) i,
  ];

  /// The current range of [issue] in the local document (null = stale).
  ResolvedRange? resolve(ProofreadIssue issue) {
    final doc = WonkyDocument(ai.doc.editor.delta);
    final matches = AddressResolver.of(doc).findQuote(issue.quote);
    if (matches.isEmpty) return null;
    final byOccurrence =
        issue.occurrence >= 1 && issue.occurrence <= matches.length
        ? matches[issue.occurrence - 1]
        : null;
    if (byOccurrence != null &&
        (byOccurrence.start - issue.start).abs() < 200) {
      return ResolvedRange(byOccurrence.start, issue.quote.length);
    }
    var best = matches.first;
    for (final m in matches) {
      if ((m.start - issue.start).abs() < (best.start - issue.start).abs()) {
        best = m;
      }
    }
    return ResolvedRange(best.start, issue.quote.length);
  }

  void _revalidate() {
    for (final i in issues) {
      if (i.status == ProofreadIssueStatus.open && resolve(i.issue) == null) {
        i.status = ProofreadIssueStatus.stale;
      }
    }
  }

  /// Accepts [ids] as one undoable change.
  bool accept(List<ProofreadIssueState> states, {String? label}) {
    final d = ai.doc.editor.delta;
    final doc = WonkyDocument(d);
    final edits = <(ResolvedRange, ProofreadIssueState)>[];
    for (final s in states) {
      if (s.status != ProofreadIssueStatus.open) continue;
      final r = resolve(s.issue);
      if (r == null) {
        s.status = ProofreadIssueStatus.stale;
        continue;
      }
      if (edits.any(
        (e) =>
            e.$1.start < r.start + r.length &&
            r.start < e.$1.start + e.$1.length,
      )) {
        continue; // Overlapping issue: accept separately.
      }
      edits.add((r, s));
    }
    if (edits.isEmpty) {
      notifyListeners();
      return false;
    }
    edits.sort((a, b) => a.$1.start.compareTo(b.$1.start));
    final change = Delta();
    var pos = 0;
    for (final (r, s) in edits) {
      if (r.start > pos) change.retain(r.start - pos);
      change.delete(r.length);
      final attrs = <String, dynamic>{
        for (final e
            in (doc.attributesAt(r.start) ?? const <String, dynamic>{}).entries)
          if (!WonkyAttr.isSuggestion(e.key)) e.key: e.value,
      };
      change.insert(s.issue.replacement, attrs.isEmpty ? null : attrs);
      pos = r.start + r.length;
    }
    final normalized = const WonkyDeltaNormalizer().normalizeChange(d, change);
    final ok = ai.applyChange(
      d,
      normalized.change,
      label ??
          (edits.length == 1
              ? ai.l10n.proofreadUndoFix(edits.single.$2.issue.quote)
              : ai.l10n.proofreadUndoAcceptMany(edits.length)),
    );
    if (ok) {
      for (final (_, s) in edits) {
        s.status = ProofreadIssueStatus.accepted;
      }
    }
    _revalidate();
    notifyListeners();
    return ok;
  }

  void dismiss(ProofreadIssueState s) {
    s.status = ProofreadIssueStatus.dismissed;
    notifyListeners();
  }

  /// Reveals the issue's text.
  void show(ProofreadIssueState s) {
    final r = resolve(s.issue);
    if (r == null) return;
    ai.doc.commands.selectRange(r.start, r.start + r.length);
    ai.doc.reveal(r.start);
  }
}

/// The issue list in the panel's proofreading card.
class ProofreadIssueList extends StatelessWidget {
  const ProofreadIssueList({super.key, required this.results});

  final ProofreadResults results;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: results,
      builder: (context, _) {
        final theme = ShadTheme.of(context);
        final l = writeL10n(context);
        final r = results;
        final children = <Widget>[];
        if (!r.finished) {
          children.add(
            Text(
              r.sectionsTotal == 0
                  ? l.proofreadInProgress
                  : l.proofreadProgress(r.sectionsDone, r.sectionsTotal),
              style: theme.textTheme.muted,
            ),
          );
        }
        if (r.finished && r.issues.isEmpty && r.error == null) {
          children.add(
            Text(
              l.proofreadNoIssues,
              key: const ValueKey<String>('proofread.none'),
              style: theme.textTheme.small,
            ),
          );
        }
        final open = r.open;
        if (open.length > 1) {
          children.add(
            Align(
              alignment: Alignment.centerLeft,
              child: ShadButton.outline(
                key: const ValueKey<String>('proofread.acceptAll'),
                size: ShadButtonSize.sm,
                enabled: r.ai.canWrite,
                onPressed: () => r.accept(open),
                child: Text(l.proofreadAcceptAllCount(open.length)),
              ),
            ),
          );
        }
        for (final c in ProofreadResults.categories) {
          final items = r.inCategory(c);
          if (items.isEmpty) continue;
          final openInCat = [
            for (final i in items)
              if (i.status == ProofreadIssueStatus.open) i,
          ];
          children.add(
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.proofreadCategoryCount(
                        ProofreadResults.categoryLabel(l, c),
                        items.length,
                      ),
                      style: theme.textTheme.small.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (openInCat.length > 1)
                    ShadButton.link(
                      key: ValueKey<String>('proofread.acceptCategory.$c'),
                      size: ShadButtonSize.sm,
                      enabled: r.ai.canWrite,
                      onPressed: () => r.accept(
                        openInCat,
                        label: l.proofreadUndoAcceptCategory(c),
                      ),
                      child: Text(l.proofreadAcceptAll),
                    ),
                ],
              ),
            ),
          );
          for (final i in items) {
            children.add(_IssueTile(results: r, state: i));
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: children,
        );
      },
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile({required this.results, required this.state});

  final ProofreadResults results;
  final ProofreadIssueState state;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final s = state;
    final open = s.status == ProofreadIssueStatus.open;
    final muted = !open;
    final l = writeL10n(context);
    return Opacity(
      opacity: muted ? 0.55 : 1,
      child: Container(
        key: ValueKey<String>('proofread.issue.${s.issue.id}'),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: cs.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 4,
          children: [
            GestureDetector(
              onTap: () => results.show(s),
              child: Semantics(
                button: true,
                hint: l.proofreadShowIssue(s.issue.quote),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: s.issue.quote,
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: cs.destructive,
                        ),
                      ),
                      const TextSpan(text: '  →  '),
                      TextSpan(
                        text: s.issue.replacement,
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  style: theme.textTheme.small,
                ),
              ),
            ),
            if (s.issue.explanation.isNotEmpty)
              Text(
                s.issue.explanation,
                style: theme.textTheme.muted.copyWith(fontSize: 12),
              ),
            Row(
              children: switch (s.status) {
                ProofreadIssueStatus.open => [
                  ShadButton.outline(
                    key: ValueKey<String>('proofread.accept.${s.issue.id}'),
                    size: ShadButtonSize.sm,
                    enabled: results.ai.canWrite,
                    onPressed: () => results.accept([s]),
                    child: Text(l.proofreadAccept),
                  ),
                  const SizedBox(width: 6),
                  ShadButton.ghost(
                    key: ValueKey<String>('proofread.dismiss.${s.issue.id}'),
                    size: ShadButtonSize.sm,
                    onPressed: () => results.dismiss(s),
                    child: Text(l.proofreadDismiss),
                  ),
                ],
                ProofreadIssueStatus.accepted => [
                  Text(l.proofreadAccepted, style: theme.textTheme.muted),
                ],
                ProofreadIssueStatus.dismissed => [
                  Text(l.proofreadDismissed, style: theme.textTheme.muted),
                ],
                ProofreadIssueStatus.stale => [
                  Text(l.proofreadTextChanged, style: theme.textTheme.muted),
                ],
              },
            ),
          ],
        ),
      ),
    );
  }
}
