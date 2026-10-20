import 'package:serverpod/serverpod.dart';

import '../common/guarded.dart';
import 'publication_webhooks.dart';

/// Webhook deliveries of publications (specs/18 §7.2): one right after an
/// event, and the sweep of due retries (`wonky.publicationSweep`, every
/// minute).
class PublicationsFutureCall extends FutureCall {
  Future<void> deliver(Session session, int deliveryId) => runGuarded<bool>(
    session,
    'publications.deliver $deliveryId',
    () => PublicationWebhooks.attempt(session, deliveryId),
  );

  Future<void> sweep(Session session) => runGuarded<int>(
    session,
    'publications.sweep',
    () async =>
        await PublicationWebhooks.sweep(session) +
        await PublicationWebhooks.purgeOld(session),
    describe: describeCount,
  );
}
