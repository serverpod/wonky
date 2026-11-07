import 'package:wonky_client/wonky_client.dart';

import 'api.dart';

/// Link-shared items for signed-out viewers (`publicItem.get`, specs/06
/// §2.4): the one drive call a guest may make.
abstract class PublicItemRepository {
  /// The document, spreadsheet or presentation [uuid] (drive item uuid or
  /// content ref) when "Anyone with the link" may view it; throws a
  /// `notFound` [WonkyException] otherwise.
  Future<PublicItemView> get(UuidValue uuid);
}

/// [PublicItemRepository] over the generated client.
class ServerPublicItemRepository implements PublicItemRepository {
  ServerPublicItemRepository(this.api);

  final Api api;

  @override
  Future<PublicItemView> get(UuidValue uuid) =>
      api.guard((c) => c.publicItem.get(uuid));
}

/// No public items (shells built without a [PublicItemRepository]).
class NoPublicItemRepository implements PublicItemRepository {
  const NoPublicItemRepository();

  @override
  Future<PublicItemView> get(UuidValue uuid) async =>
      throw WonkyException(code: WonkyErrorCode.notFound, message: 'Not found');
}

/// The zero uuid of the guest item's owner (guests learn no ids of people).
final _nobody = UuidValue.fromString('00000000-0000-0000-0000-000000000000');

/// The drive item a signed-out viewer opens [view] as: view-only, no
/// parent, the owner by name only.
DriveItemView guestItemView(PublicItemView view) => DriveItemView(
  uuid: view.uuid,
  kind: view.kind,
  name: view.name,
  contentRef: view.contentRef,
  owner: UserSummary(
    id: 0,
    uuid: _nobody,
    displayName: view.ownerName,
    email: '',
    avatarColor: '#64748b',
    colorIndex: 0,
  ),
  role: AccessRole.viewer,
  shared: true,
  linkRole: AccessRole.viewer,
  sizeBytes: 0,
  createdAt: view.modifiedAt,
  modifiedAt: view.modifiedAt,
  starred: false,
  pinnedOffline: false,
  editorsCanShare: false,
  nonEditorsCanExport: false,
  viewersSeeComments: false,
);
