import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../l10n/write_l10n.dart';
import '../screen/write_document_controller.dart';
import 'submission_controller.dart';

/// The status chip and *Submit* button of a document with a submission
/// (specs/18 §4.1), right before *Share*. Nothing shows for documents
/// without one.
class SubmissionTitleActions extends StatefulWidget {
  const SubmissionTitleActions({
    super.key,
    required this.services,
    required this.doc,
  });

  final ShellServices services;
  final WriteDocumentController doc;

  @override
  State<SubmissionTitleActions> createState() => _SubmissionTitleActionsState();
}

class _SubmissionTitleActionsState extends State<SubmissionTitleActions> {
  final _popover = ShadPopoverController();

  SubmissionController get c => widget.doc.submission;
  ShellServices get s => widget.services;

  @override
  void initState() {
    super.initState();
    c.popoverRequests.addListener(_openPopover);
  }

  @override
  void dispose() {
    c.popoverRequests.removeListener(_openPopover);
    _popover.dispose();
    super.dispose();
  }

  void _openPopover() {
    if (mounted && c.hasSubmission) _popover.show();
  }

  void _invoke(String id) => unawaited(
    s.dispatcher
        .invoke(id, source: InvocationSource.ui, context: context)
        .catchError((Object e) {
          s.toasts.error(
            s.l10n?.errorGeneric ?? 'Error',
            description: errorMessage(e),
          );
          return const CommandResult.cancelled();
        }),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([c, s.registry, s.activeDocument]),
    builder: (context, _) {
      final v = c.view;
      if (v == null) return const SizedBox.shrink();
      final l = writeL10n(context);
      final compact = MediaQuery.sizeOf(context).width < 1200;
      final showButton =
          widget.doc.role >= Role.editor &&
          v.status != SubmissionStatus.declined &&
          v.accepting;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (v.status != SubmissionStatus.draft) ...[
            _chip(context, v),
            const SizedBox(width: 6),
          ],
          if (showButton) ...[
            _button(context, v, l, compact),
            const SizedBox(width: 6),
          ],
        ],
      );
    },
  );

  Widget _button(
    BuildContext context,
    SubmissionView v,
    WriteLocalizations l,
    bool compact,
  ) {
    final state = s.dispatcher.stateOf('write.submission.submit');
    final label = switch (v.status) {
      SubmissionStatus.draft || SubmissionStatus.withdrawn => l.submitButton,
      SubmissionStatus.published => l.submitUpdateButton,
      _ => l.resubmitButton,
    };
    final tip = !state.enabled && state.disabledReason != null
        ? state.disabledReason!
        : l.submitTooltip(v.publicationName);
    return ShadTooltip(
      builder: (_) => Text(tip),
      child: compact
          ? ShadIconButton.secondary(
              key: const ValueKey<String>('write.submission.submit'),
              width: 32,
              height: 32,
              iconSize: 16,
              semanticLabel: label,
              enabled: state.enabled,
              icon: c.busy
                  ? const SizedBox.square(dimension: 14, child: ShadSpinner())
                  : const Icon(LucideIcons.send),
              onPressed: () => _invoke('write.submission.submit'),
            )
          : ShadButton.secondary(
              key: const ValueKey<String>('write.submission.submit'),
              height: 32,
              enabled: state.enabled,
              leading: c.busy
                  ? const SizedBox.square(dimension: 14, child: ShadSpinner())
                  : const Icon(LucideIcons.send, size: 14),
              onPressed: () => _invoke('write.submission.submit'),
              child: Text(label),
            ),
    );
  }

  Widget _chip(BuildContext context, SubmissionView v) {
    final theme = ShadTheme.of(context);
    final app = WonkyAppLocalizations.of(context);
    final l = writeL10n(context);
    final pending = v.delivery == SubmissionDeliveryState.pending;
    final (Color fg, Color bg) = switch (v.status) {
      SubmissionStatus.changesRequested => (
        theme.colorScheme.foreground,
        theme.colorScheme.warning.withValues(alpha: 0.18),
      ),
      SubmissionStatus.published => (
        theme.colorScheme.foreground,
        theme.colorScheme.success.withValues(alpha: 0.18),
      ),
      _ => (theme.colorScheme.mutedForeground, theme.colorScheme.muted),
    };
    final text = pending
        ? l.submittingChip
        : submissionStatusLabel(app, v.status);
    return ShadPopover(
      controller: _popover,
      anchor: const ShadAnchor(
        childAlignment: AlignmentDirectional.bottomEnd,
        overlayAlignment: AlignmentDirectional.topEnd,
        offset: Offset(0, 6),
      ),
      popover: (context) =>
          _StatusPopover(services: s, doc: widget.doc, onClose: _popover.hide),
      child: ShadButton.ghost(
        key: const ValueKey<String>('write.submission.chip'),
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        backgroundColor: bg,
        foregroundColor: fg,
        leading: const Icon(LucideIcons.newspaper, size: 14),
        onPressed: _popover.toggle,
        child: Text(text, style: theme.textTheme.small.copyWith(color: fg)),
      ),
    );
  }
}

/// The status popover (specs/18 §4.3).
class _StatusPopover extends StatelessWidget {
  const _StatusPopover({
    required this.services,
    required this.doc,
    required this.onClose,
  });

  final ShellServices services;
  final WriteDocumentController doc;
  final VoidCallback onClose;

  String _date(DateTime d) =>
      intl.DateFormat.yMMMd().add_Hm().format(d.toLocal());

  void _invoke(BuildContext context, String id, [JsonArgs? args]) {
    onClose();
    unawaited(
      services.dispatcher
          .invoke(
            id,
            args: args?.values ?? const {},
            source: InvocationSource.ui,
            context: context,
          )
          .catchError((Object e) {
            services.toasts.error(
              services.l10n?.errorGeneric ?? 'Error',
              description: errorMessage(e),
            );
            return const CommandResult.cancelled();
          }),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: doc.submission,
    builder: (context, _) {
      final v = doc.submission.view;
      if (v == null) return const SizedBox.shrink();
      final l = writeL10n(context);
      final app = WonkyAppLocalizations.of(context);
      final theme = ShadTheme.of(context);
      final c = doc.submission;
      final last = v.revisions.isEmpty ? null : v.revisions.last;
      return SizedBox(
        width: 320,
        child: Column(
          key: const ValueKey<String>('write.submission.popover'),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.newspaper, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    v.publicationName,
                    style: theme.textTheme.small.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              v.verified
                  ? '${v.shownHost} ✓'
                  : l.submitNotVerified(v.shownHost),
              style: theme.textTheme.muted.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 10),
            Text(
              v.delivery == SubmissionDeliveryState.pending
                  ? l.submittingChip
                  : v.delivery == SubmissionDeliveryState.failed
                  ? l.submitDeliveryFailed(v.publicationName)
                  : submissionStatusLabel(app, v.status),
              style: theme.textTheme.small,
            ),
            if (last != null)
              Text(
                l.submittedBy(
                  last.submittedByName,
                  _date(last.submittedAt),
                  last.sequence,
                ),
                style: theme.textTheme.muted.copyWith(fontSize: 12),
              ),
            if (v.lastMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.muted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  v.lastMessage!,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.small,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (v.feedbackThreadUuid != null)
                  ShadButton.outline(
                    key: const ValueKey<String>('write.submission.openThread'),
                    size: ShadButtonSize.sm,
                    onPressed: () => _invoke(
                      context,
                      'write.comments.activate',
                      JsonArgs({'threadUuid': v.feedbackThreadUuid!.uuid}),
                    ),
                    child: Text(l.submitOpenThread),
                  ),
                if (v.publicUrl != null)
                  ShadButton.outline(
                    key: const ValueKey<String>('write.submission.viewPost'),
                    size: ShadButtonSize.sm,
                    onPressed: () {
                      onClose();
                      unawaited(services.crossApp.openExternal(v.publicUrl!));
                    },
                    child: Text(l.submitViewPost),
                  ),
                if (c.canWithdraw)
                  ShadButton.ghost(
                    key: const ValueKey<String>('write.submission.withdraw'),
                    size: ShadButtonSize.sm,
                    onPressed: () =>
                        _invoke(context, 'write.submission.withdraw'),
                    child: Text(l.cmdSubmissionWithdraw),
                  ),
                if (c.canDisconnect && doc.role >= Role.editor)
                  ShadButton.ghost(
                    key: const ValueKey<String>('write.submission.disconnect'),
                    size: ShadButtonSize.sm,
                    onPressed: () =>
                        _invoke(context, 'write.submission.disconnect'),
                    child: Text(l.submitDisconnect(v.publicationName)),
                  ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
