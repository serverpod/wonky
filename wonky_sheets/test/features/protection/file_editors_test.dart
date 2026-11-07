import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_sheets/config/sheets_app_config.dart';
import 'package:wonky_sheets/features/in_cell/cell_features.dart';
import 'package:wonky_sheets/features/model/local_view_state.dart';
import 'package:wonky_sheets/features/protection/file_editors.dart';
import 'package:wonky_sheets/features/protection/protection_controller.dart';
import 'package:wonky_sheets/features/sheet_editor/view_state_binding.dart';

import '../../support/sheets_harness.dart';

final _item = UuidValue.fromString('00000000-0000-7000-8000-00000000a001');

UserSummary _user(int n, String name, String email) => UserSummary(
  id: n,
  uuid: UuidValue.fromString(
    '00000000-0000-7000-8000-${n.toString().padLeft(12, '0')}',
  ),
  displayName: name,
  email: email,
  avatarColor: '#000000',
  colorIndex: 0,
);

/// Sharing of one spreadsheet: the owner Ann, editor Bo; `share` adds
/// accounts it knows (Cy) and invites other emails.
class _Sharing implements SharingRepository {
  final List<PermissionView> permissions = [
    PermissionView(
      user: _user(2, 'Bo', 'bo@x.com'),
      role: AccessRole.editor,
      grantedAt: DateTime.utc(2026),
    ),
  ];
  final known = {'cy@x.com': _user(3, 'Cy', 'cy@x.com')};
  bool offline = false;

  SharingInfo _info() => SharingInfo(
    itemUuid: _item,
    itemName: 'Budget',
    itemKind: DriveItemKind.spreadsheet,
    owner: _user(1, 'Ann', 'ann@x.com'),
    myRole: AccessRole.owner,
    canShare: true,
    permissions: List.of(permissions),
    generalAccess: GeneralAccess.restricted,
    settings: ItemSharingSettings(
      editorsCanShare: true,
      nonEditorsCanExport: true,
      viewersSeeComments: true,
    ),
    pendingRequests: const [],
  );

  @override
  Future<SharingInfo> getSharing(UuidValue itemUuid) async {
    if (offline) throw StateError('offline');
    return _info();
  }

  @override
  Future<SharingInfo> share(
    UuidValue itemUuid, {
    required List<String> emails,
    required AccessRole role,
    bool notify = true,
    String? message,
    DateTime? expiresAt,
  }) async {
    for (final e in emails) {
      final u = known[e];
      permissions.add(
        PermissionView(
          user: u,
          invitedEmail: u == null ? e : null,
          role: role,
          grantedAt: DateTime.utc(2026),
        ),
      );
    }
    return _info();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Given the sharing of a spreadsheet', () {
    late CommandTestHarness h;
    late _Sharing sharing;

    setUp(() {
      sharing = _Sharing();
      h = CommandTestHarness(config: const SheetsAppConfig(), sharing: sharing);
    });
    tearDown(() => h.dispose());

    test('when loading online then the owner and editors are listed and '
        'cached; offline the cached list is used', () async {
      final online = await FileEditors.load(h.services, _item);
      expect(online.offline, isFalse);
      expect(online.editors.map((e) => e.label), ['Ann', 'Bo']);

      sharing.offline = true;
      final offline = await FileEditors.load(
        h.services,
        _item,
        known: ['00000000-0000-7000-8000-0000000000ee'],
      );
      expect(offline.offline, isTrue);
      expect(offline.editors.map((e) => e.label), [
        'Ann',
        'Bo',
        '00000000-0000-7000-8000-0000000000ee',
      ]);
      expect(offline.editors[1].email, 'bo@x.com');
    });

    test('when inviting emails then accounts become user ids and the others '
        'are invited', () async {
      final r = await FileEditors.invite(h.services, _item, [
        'cy@x.com',
        'new@x.com',
      ]);
      expect(r.userIds, {'cy@x.com': _user(3, 'Cy', 'cy@x.com').uuid.uuid});
      expect(r.invited, ['new@x.com']);
      final cached = await FileEditors.cached(h.services, _item);
      expect(cached.map((e) => e.label), ['Ann', 'Bo', 'Cy']);
    });
  });

  group('Given an open spreadsheet', () {
    late SheetsHarness s;
    setUp(() {
      s = SheetsHarness.open();
      attachCellFeatures(s.editor);
    });
    tearDown(() => s.dispose());

    test('when hiding protected ranges then the choice is kept in the '
        "user's view state and restored", () async {
      final store = LocalViewStateStore(s.services.userStore);
      final b = ViewStateBinding.attach(s.editor, store);
      ProtectionController.of(s.editor).showStripes = false;

      final state = b.capture();
      expect(state.showProtectedRanges, isFalse);
      final back = LocalViewState.fromJson(state.toJson())!;
      expect(back.showProtectedRanges, isFalse);
      expect(
        LocalViewState.fromJson({
          'at': DateTime.utc(2026).toIso8601String(),
        })!.showProtectedRanges,
        isTrue,
      );

      await b.save();
      ProtectionController.of(s.editor).showStripes = true;
      ViewStateBinding.attach(s.editor, store);
      expect(ProtectionController.of(s.editor).showStripes, isFalse);
    });
  });
}
