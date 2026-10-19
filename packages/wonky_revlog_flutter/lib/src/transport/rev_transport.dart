import 'package:wonky_client/wonky_client.dart';

/// The server API of one app's RevLog endpoint (RevLog spec 04 §1):
/// `client.sheetsDoc` or `client.slidesDoc`.
abstract interface class RevTransport {
  /// Opens a session on [fileUuid] (04 §2).
  Stream<RevServerMessage> connect(
    UuidValue fileUuid,
    int knownRevision,
    String tabId,
    Stream<RevClientMessage> input,
  );

  /// A bootstrap page (04 §3).
  Future<RevPage> page(UuidValue fileUuid, RevPageRequest request);

  /// Ops in (from, to] (04 §1).
  Future<List<RevOpView>> ops(UuidValue fileUuid, int from, int to);

  /// Head revision, role and stats.
  Future<RevFileInfo> info(UuidValue fileUuid);
}

/// [RevTransport] over generated endpoint calls.
final class ClientRevTransport implements RevTransport {
  /// Creates the transport from the endpoint's methods.
  const ClientRevTransport({
    required this.onConnect,
    required this.onPage,
    required this.onOps,
    required this.onInfo,
  });

  /// Spreadsheets (`client.sheetsDoc`).
  factory ClientRevTransport.sheets(Client client) => ClientRevTransport(
    onConnect: client.sheetsDoc.connect,
    onPage: client.sheetsDoc.page,
    onOps: client.sheetsDoc.ops,
    onInfo: client.sheetsDoc.info,
  );

  /// Presentations (`client.slidesDoc`).
  factory ClientRevTransport.slides(Client client) => ClientRevTransport(
    onConnect: client.slidesDoc.connect,
    onPage: client.slidesDoc.page,
    onOps: client.slidesDoc.ops,
    onInfo: client.slidesDoc.info,
  );

  final Stream<RevServerMessage> Function(
    UuidValue fileUuid,
    int knownRevision,
    String tabId,
    Stream<RevClientMessage> input,
  )
  onConnect;
  final Future<RevPage> Function(UuidValue fileUuid, RevPageRequest request)
  onPage;
  final Future<List<RevOpView>> Function(UuidValue fileUuid, int from, int to)
  onOps;
  final Future<RevFileInfo> Function(UuidValue fileUuid) onInfo;

  @override
  Stream<RevServerMessage> connect(
    UuidValue fileUuid,
    int knownRevision,
    String tabId,
    Stream<RevClientMessage> input,
  ) => onConnect(fileUuid, knownRevision, tabId, input);

  @override
  Future<RevPage> page(UuidValue fileUuid, RevPageRequest request) =>
      onPage(fileUuid, request);

  @override
  Future<List<RevOpView>> ops(UuidValue fileUuid, int from, int to) =>
      onOps(fileUuid, from, to);

  @override
  Future<RevFileInfo> info(UuidValue fileUuid) => onInfo(fileUuid);
}
