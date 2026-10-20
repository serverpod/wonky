import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';

/// The document's submission to a publication (specs/18 §4): loaded once
/// the document is open and again whenever the item changes (the server
/// signals submission changes as item updates), so the title row's chip
/// and *Submit* button follow the blog's decisions live.
class SubmissionController extends ChangeNotifier {
  SubmissionController({
    required this.services,
    required this.itemUuid,
    required this.revision,
  });

  final ShellServices services;
  final UuidValue itemUuid;

  /// The document's current revision (to tell whether it changed since the
  /// last submit).
  final int Function() revision;

  SubmissionView? _view;
  bool _started = false;
  bool _busy = false;
  bool _disposed = false;
  StreamSubscription<DriveChange>? _changes;

  /// The submission, or null when the document has none.
  SubmissionView? get view => _view;
  bool get hasSubmission => _view != null;

  /// A submit, withdraw or disconnect is running.
  bool get busy => _busy;

  bool get online => services.connectivity.online;

  PublicationRepository? get _repo => services.repositories.hasPublications
      ? services.repositories.publications
      : null;

  /// Starts loading and following the submission (idempotent).
  void start() {
    if (_started || _repo == null) return;
    _started = true;
    _changes = services.driveChanges.listen((c) {
      if (c.itemUuid == itemUuid) unawaited(refresh());
    });
    services.connectivity.addListener(_onConnectivity);
    unawaited(refresh());
  }

  void _onConnectivity() {
    if (online) unawaited(refresh());
    _notify();
  }

  Future<void> refresh() async {
    final repo = _repo;
    if (repo == null) return;
    try {
      final v = await repo.submission(itemUuid);
      if (_disposed) return;
      _view = v;
      _notify();
    } catch (_) {
      // Offline or no access: keep what is shown.
    }
  }

  /// Whether the document changed since the last submit.
  bool get changedSinceSubmit {
    final last = _view?.lastSubmittedRevision;
    return last == null || revision() > last;
  }

  /// Whether the editor may press *Submit* now (specs/18 §4.1).
  bool get canSubmit {
    final v = _view;
    if (v == null || !online || _busy || !v.accepting) return false;
    if (v.status == SubmissionStatus.declined) return false;
    if (v.status == SubmissionStatus.draft ||
        v.status == SubmissionStatus.withdrawn) {
      return true;
    }
    return changedSinceSubmit;
  }

  /// Whether the story can be withdrawn.
  bool get canWithdraw {
    final s = _view?.status;
    return online &&
        !_busy &&
        (s == SubmissionStatus.inReview ||
            s == SubmissionStatus.changesRequested);
  }

  /// Whether the document can be disconnected (not while in review).
  bool get canDisconnect => online && !_busy && hasSubmission && !canWithdraw;

  Future<T> _run<T>(
    Future<T> Function(PublicationRepository repo) action,
  ) async {
    _busy = true;
    _notify();
    try {
      return await action(_repo!);
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<SubmissionView> submit(
    SubmissionValues values, {
    required bool agreed,
  }) => _run((repo) async {
    final v = await repo.submit(itemUuid, values, agreed: agreed);
    _view = v;
    return v;
  });

  Future<void> withdraw() => _run((repo) async {
    _view = await repo.withdraw(itemUuid);
  });

  Future<void> disconnect() => _run((repo) async {
    await repo.disconnect(itemUuid);
    _view = null;
  });

  Future<void> reconnect() => _run((repo) async {
    _view = await repo.reconnect(itemUuid);
  });

  /// Bumped when *Submission status* is invoked: the title row opens its
  /// popover.
  final ValueNotifier<int> popoverRequests = ValueNotifier(0);

  void requestPopover() => popoverRequests.value++;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    popoverRequests.dispose();
    unawaited(_changes?.cancel());
    if (_started) services.connectivity.removeListener(_onConnectivity);
    super.dispose();
  }
}
