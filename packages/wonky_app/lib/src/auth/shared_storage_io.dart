import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

/// Web only: desktop apps keep their session in secure storage.
ClientAuthSuccessStorage sharedSessionStorage() =>
    throw UnsupportedError('The shared session storage is web only.');

/// Web only: never fires on desktop.
Stream<void> sharedSessionChanges() => const Stream.empty();
