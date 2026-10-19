import 'dart:convert';

import 'package:mcp_dart/mcp_dart.dart' as mcp;
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/ai/ai_call.dart';
import 'package:wonky_server/src/platform/ai/llm/ai_client.dart';
import 'package:wonky_server/src/platform/common/errors.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/mcp/mcp_errors.dart';
import 'package:wonky_server/src/platform/mcp/tool_support.dart';

/// The shared AI and MCP error mapping (CQ-51): every AI feature shows the
/// same message and code for the same failure.
void main() {
  group('Given a provider error', () {
    final cases = [
      (AiApiException(401, 'api_error', 'bad key'), 'auth'),
      (AiApiException(429, 'api_error', 'slow down'), 'rate_limited'),
      (AiApiException(529, 'api_error', 'overloaded'), 'overloaded'),
      (AiApiException(0, 'timeout', 'late'), 'timeout'),
      (AiApiException(0, 'connection_error', 'reset'), 'connection'),
      (AiApiException(500, 'api_error', 'boom'), 'api_error'),
      (AiApiException(400, 'refusal', 'no'), 'refusal'),
    ];
    for (final (error, code) in cases) {
      test('when it is ${error.statusCode} ${error.type} then the failure '
          'code is $code', () {
        expect(AiFailure.fromApi(error).code, code);
      });
    }

    test('when it becomes an endpoint exception and back then the failure '
        'is the same', () {
      final failure = AiFailure.fromApi(AiApiException(429, 'api_error', 'x'));
      final e = failure.toException();

      expect(e.code, WonkyErrorCode.unavailable);
      expect(AiFailure.of(e)?.code, 'rate_limited');
      expect(AiFailure.of(e)?.message, failure.message);
    });
  });

  group('Given a refusal', () {
    test('when it becomes an endpoint exception then it is an invalid '
        'argument with the refusal code', () {
      final e = AiFailure.refusal.toException();

      expect(e.code, WonkyErrorCode.invalidArgument);
      expect(jsonDecode(e.detailsJson!), {'code': 'refusal'});
      expect(AiFailure.of(e)?.isRefusal, isTrue);
    });
  });

  group('Given other failures of a run', () {
    test('when the run is cancelled then there is nothing to show', () {
      expect(AiFailure.of(const AiCancelledException()), isNull);
    });

    test('when a service error is thrown then its code name is kept', () {
      final f = AiFailure.of(Errors.invalid('No outline.'));

      expect(f?.code, 'invalidArgument');
      expect(f?.message, 'No outline.');
    });

    test('when anything else is thrown then it is an internal error', () {
      expect(AiFailure.of(StateError('bug')), same(AiFailure.internal));
    });
  });

  group('Given a tool error', () {
    final cases = [
      (McpErrorCode.notFound, WonkyErrorCode.notFound),
      (McpErrorCode.forbidden, WonkyErrorCode.forbidden),
      (McpErrorCode.busy, WonkyErrorCode.busy),
      (McpErrorCode.conflict, WonkyErrorCode.conflict),
      ('being_edited', WonkyErrorCode.conflict),
      (McpErrorCode.tooLarge, WonkyErrorCode.tooLarge),
      (McpErrorCode.rateLimited, WonkyErrorCode.limitExceeded),
      (McpErrorCode.invalidArgs, WonkyErrorCode.invalidArgument),
    ];
    for (final (tool, wonky) in cases) {
      test('when "$tool" reaches an endpoint then it is ${wonky.name}', () {
        final e = McpErrors.toWonky(McpToolException(tool, 'Nope.'));

        expect(e.code, wonky);
        expect(e.message, 'Nope.');
        expect((jsonDecode(e.detailsJson!) as Map)['code'], tool);
      });
    }

    test('when an MCP resource fails then not found is resourceNotFound', () {
      expect(
        () => McpErrors.guardResource<void>(
          () async => throw Errors.notFound('File'),
        ),
        throwsA(
          isA<mcp.McpError>().having(
            (e) => e.code,
            'code',
            mcp.ErrorCode.resourceNotFound.value,
          ),
        ),
      );
    });
  });
}
