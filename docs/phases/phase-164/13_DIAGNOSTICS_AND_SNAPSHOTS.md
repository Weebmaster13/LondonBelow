# Diagnostics and Snapshots

Diagnostics expose `eventBusPosture`, registry counts, queue depth, delivery counters, cancellation/rejection/drop/failure counts, subscriber failures, queue overflows, recursive publish rejections, average queue depth, maximum queue depth, and last failure.

Snapshots expose:

- `eventRegistrySnapshot`
- `publisherRegistrySnapshot`
- `subscriberRegistrySnapshot`
- `queueSnapshot`
- `routingSnapshot`
- `dispatchSnapshot`
- `cancellationSnapshot`
- `diagnosticsSnapshot`
- `evidenceSnapshot`

Snapshots are immutable deep copies.
