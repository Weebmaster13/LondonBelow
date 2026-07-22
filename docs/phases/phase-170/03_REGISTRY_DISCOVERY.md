# Registry And Discovery

`CapabilityRegistry` owns registration, lookup, version metadata, and duplicate id rejection.

`CapabilityDiscovery` resolves interfaces deterministically by:

- interface identifier;
- version;
- optional owner.

Discovery returns immutable match records and records evidence. Consumers must resolve capability interfaces instead of caching implementation references permanently.
