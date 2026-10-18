@Tags(['integration'])
library;

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';

import '../../../support/mcp_harness.dart';
import '../../../support/test_drive.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

/// One tool call of the matrix: [allowed] roles succeed, others fail with
/// `forbidden` or (no access) `not_found`.
typedef _Case = ({
  String tool,
  Map<String, Object?> Function(String uuid) args,
  Set<AccessRole?> allowed,
});

final List<_Case> _cases = [
  (
    tool: 'write.get_document',
    args: (u) => {'document_uuid': u},
    allowed: {
      AccessRole.owner,
      AccessRole.editor,
      AccessRole.commenter,
      AccessRole.viewer,
    },
  ),
  (
    tool: 'write.insert_markdown',
    args: (u) => {
      'document_uuid': u,
      'markdown': 'More',
      'at': {'type': 'end'},
      'mode': 'edit',
    },
    allowed: {AccessRole.owner, AccessRole.editor},
  ),
  (
    tool: 'write.insert_markdown',
    args: (u) => {
      'document_uuid': u,
      'markdown': 'More',
      'at': {'type': 'end'},
      'mode': 'suggest',
    },
    allowed: {AccessRole.owner, AccessRole.editor, AccessRole.commenter},
  ),
  (
    tool: 'comments.create',
    args: (u) => {
      'uuid': u,
      'anchor': {'quote': 'Hello'},
      'body': 'Note',
    },
    allowed: {AccessRole.owner, AccessRole.editor, AccessRole.commenter},
  ),
  (
    tool: 'write.update_page_setup',
    args: (u) => {
      'document_uuid': u,
      'patch': {'layout': 'pageless'},
    },
    allowed: {AccessRole.owner, AccessRole.editor},
  ),
  (
    tool: 'drive.rename',
    args: (u) => {'uuid': u, 'name': 'Renamed'},
    allowed: {AccessRole.owner, AccessRole.editor},
  ),
  (
    tool: 'drive.set_link_sharing',
    args: (u) => {'uuid': u, 'mode': 'viewer'},
    // Editors may share by default (editorsCanShare).
    allowed: {AccessRole.owner, AccessRole.editor},
  ),
  (
    tool: 'versions.list',
    args: (u) => {'uuid': u},
    allowed: {AccessRole.owner, AccessRole.editor},
  ),
];

void main() {
  withWonkyServerpod('Given a document shared with each role', (
    sessionBuilder,
    endpoints,
  ) {
    for (final c in _cases) {
      final mode = c.tool.startsWith('write.') ? c.args('x')['mode'] : null;
      group('Given ${c.tool}${mode == null ? '' : ' (mode $mode)'}', () {
        for (final role in allRoles) {
          final ok = c.allowed.contains(role);
          test(
            'when called by ${role?.name ?? 'someone without access'} then it '
            '${ok ? 'succeeds' : 'is refused'}',
            () async {
              final owner = await TestUsers.create(sessionBuilder, name: 'O');
              final doc = await TestDrive.document(
                endpoints,
                owner,
                markdown: 'Hello world.',
              );
              var caller = owner;
              if (role != AccessRole.owner) {
                caller = await TestUsers.create(sessionBuilder, name: 'C');
                if (role != null) {
                  await TestDrive.share(endpoints, doc, owner, caller, role);
                }
              }
              final mcp = await McpHarness.forUser(caller);

              if (ok) {
                await mcp.call(c.tool, c.args(doc.uuid.uuid));
              } else {
                final e = await mcp.error(c.tool, c.args(doc.uuid.uuid));
                expect(
                  e['code'],
                  role == null ? 'not_found' : 'forbidden',
                  reason: '$e',
                );
              }
            },
          );
        }
      });
    }
  });
}
