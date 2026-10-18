import 'dart:async';
import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../common/actor.dart';
import '../common/models.dart';
import 'ai_keys.dart';
import 'ai_models.dart';
import 'ai_usage_service.dart';
import 'llm/ai_client.dart';

/// Why an AI request or run failed, as shown to the user: the text and a
/// stable code (`refusal`, `auth`, `rate_limited`, `overloaded`, `timeout`,
/// `connection`, `api_error`, a [WonkyErrorCode] name or `internal`).
final class AiFailure {
  const AiFailure(this.message, this.code);

  /// Shown when the provider refuses a request.
  static const refusalText = "The assistant can't help with that request.";

  /// Shown for unexpected failures.
  static const internalText = 'Something went wrong. Please try again.';

  static const refusal = AiFailure(refusalText, 'refusal');
  static const internal = AiFailure(internalText, 'internal');

  final String message;
  final String code;

  bool get isRefusal => code == 'refusal';

  /// The failure of [e]; null when [e] is a cancellation (nothing to show).
  static AiFailure? of(Object e) {
    if (e is AiCancelledException) return null;
    if (e is AiApiException) return fromApi(e);
    if (e is WonkyException) {
      final details = e.detailsJson;
      if (details != null) {
        try {
          final code = (jsonDecode(details) as Map?)?['code'];
          if (code == 'refusal') return refusal;
          if (code is String && e.code == WonkyErrorCode.unavailable) {
            return AiFailure(e.message, code);
          }
        } on FormatException {
          // Not JSON: fall back to the error code.
        }
      }
      return AiFailure(e.message, e.code.name);
    }
    return internal;
  }

  /// The user-facing failure of a provider error.
  static AiFailure fromApi(AiApiException e) {
    if (e.type == 'refusal') return refusal;
    return AiFailure(_apiMessage(e), _apiCode(e));
  }

  /// The endpoint exception of this failure (`invalidArgument` for a
  /// refusal, `unavailable` for provider errors); `detailsJson` carries the
  /// [code].
  WonkyException toException() => WonkyException(
    code: isRefusal
        ? WonkyErrorCode.invalidArgument
        : WonkyErrorCode.unavailable,
    message: message,
    detailsJson: jsonEncode({'code': code}),
  );

  static String _apiMessage(AiApiException e) {
    if (e.isAuth) {
      return 'The AI provider rejected the API key. Check the key in '
          'Settings › AI providers, or ask an administrator.';
    }
    if (e.isRateLimit || e.isOverloaded) {
      return 'The AI service is busy right now. Try again in a moment.';
    }
    if (e.type == 'timeout') return 'The AI service took too long to answer.';
    if (e.statusCode == 0) {
      return 'The connection to the AI service was interrupted. Try again.';
    }
    if (e.statusCode == 413) return 'The request is too large for the model.';
    return 'The AI service returned an error. Try again.';
  }

  static String _apiCode(AiApiException e) {
    if (e.isAuth) return 'auth';
    if (e.isRateLimit) return 'rate_limited';
    if (e.isOverloaded) return 'overloaded';
    if (e.type == 'timeout') return 'timeout';
    if (e.statusCode == 0) return 'connection';
    return 'api_error';
  }

  @override
  String toString() => 'AiFailure($code: $message)';
}

/// The shared scaffolding of the AI features (CQ-51): availability and
/// budget, the user's backend, one model turn with its concurrency slot,
/// usage record and error mapping, and background runs streamed to the
/// client with cancellation.
///
/// ```dart
/// final call = await AiCall.open(session, actor);
/// final r = await call.send(session, request);            // one turn
/// return call.stream(session, (s, cancel, emit) async {…},  // a run
///     onFailure: (f) => Event.error(f));
/// ```
final class AiCall {
  AiCall._(this.userId, this.backend);

  /// Checks that AI is available to [actor] and the day's budget is not
  /// spent (one usage query), and resolves the user's backend. Throws a
  /// [WonkyException] (`unavailable`, `limitExceeded`).
  static Future<AiCall> open(Session session, Actor actor) async {
    await AiUsageService.requireAvailable(session, actor.userId);
    final backend = await AiKeys.backendFor(session, actor.userId);
    if (backend == null) {
      throw WonkyException(
        code: WonkyErrorCode.unavailable,
        message: AiUsageService.notConfiguredMessage,
      );
    }
    return AiCall._(actor.userId, backend);
  }

  final int userId;
  final AiBackend backend;

  /// Budget tokens used by this call's turns so far ([send]).
  int get usedTokens => _usedTokens;
  int _usedTokens = 0;

  /// Whether a [stream] run holds the concurrency slot for its turns.
  bool _holdsSlot = false;

  /// The model id of [tier] for the user's provider.
  String model(AiTier tier) => backend.model(tier);

  /// The user's quality setting.
  Future<AiQuality> quality(Session session) =>
      AiUsageService.quality(session, userId);

  /// Throws `limitExceeded` when the day's budget is spent (between the
  /// turns of a long run).
  Future<void> requireBudget(Session session) =>
      AiUsageService.requireBudget(session, userId);

  /// One model turn: takes one of the user's concurrency slots (unless a
  /// [stream] run already holds it), records the usage in [session], and
  /// maps a refusal and provider errors to [WonkyException]s (see
  /// [AiFailure.toException]). [AiCancelledException] passes through.
  Future<AiResponse> send(
    Session session,
    AiRequest request, {
    AiCancelToken? cancel,
    void Function(String delta)? onText,
  }) async {
    final release = _holdsSlot ? null : AiUsageService.acquire(userId);
    try {
      final r = await backend.client.send(
        request,
        cancel: cancel,
        onText: onText,
      );
      _usedTokens += AiUsageService.budgetTokens(r.usage);
      await AiUsageService.record(
        session,
        userId: userId,
        model: r.model ?? request.model,
        feature: request.feature,
        usage: r.usage,
      );
      if (r.stopReason == AiStopReason.refusal) {
        throw AiFailure.refusal.toException();
      }
      return r;
    } on AiApiException catch (e) {
      throw AiFailure.fromApi(e).toException();
    } finally {
      release?.call();
    }
  }

  /// Runs [body] in the background in its own session (or [runSession]'s,
  /// left open; tests) and streams what it emits. The run holds one of the
  /// user's concurrency slots until it ends (taken now, so a busy user gets
  /// the error before the stream starts); its [send]s don't take another.
  /// Closing the stream cancels the run. A failure of [body] is emitted as
  /// `onFailure(…)` (a cancellation is not), then the stream closes.
  Stream<E> stream<E>(
    Session session,
    Future<void> Function(
      Session s,
      AiCancelToken cancel,
      void Function(E) emit,
    )
    body, {
    required E Function(AiFailure failure) onFailure,
    Future<Session> Function()? runSession,
  }) {
    final release = AiUsageService.acquire(userId);
    _holdsSlot = true;
    final cancel = AiCancelToken();
    final out = StreamController<E>();
    out.onCancel = cancel.cancel;
    void emit(E e) {
      if (!out.isClosed) out.add(e);
    }

    final pod = session.serverpod;
    Future<void> run() async {
      final s = runSession == null
          ? await pod.createSession(enableLogging: false)
          : await runSession();
      try {
        await body(s, cancel, emit);
      } on Object catch (e, st) {
        final failure = AiFailure.of(e);
        if (failure == AiFailure.internal) {
          s.log(
            'AI run failed: $e',
            level: LogLevel.warning,
            exception: e,
            stackTrace: st,
          );
        }
        if (failure != null) emit(onFailure(failure));
      } finally {
        if (runSession == null) await s.close();
      }
    }

    unawaited(
      run()
          .catchError((Object e, StackTrace st) {
            pod.logVerbose('AI run failed: $e\n$st');
            emit(onFailure(AiFailure.internal));
          })
          .whenComplete(() {
            _holdsSlot = false;
            release();
            if (!out.isClosed) unawaited(out.close());
          }),
    );
    return out.stream;
  }
}

/// The events of the inline AI streams (Write, Sheets, Slides).
extension AiFailureEvents on AiFailure {
  /// A `refusal` or `error` event with the message and code.
  InlineAiEvent get inlineEvent => InlineAiEvent(
    type: isRefusal ? InlineAiEventType.refusal : InlineAiEventType.error,
    error: message,
    errorCode: code,
  );
}
