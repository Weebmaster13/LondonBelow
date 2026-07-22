# Identity And Interface Ownership

`DomainIdentityRegistry` owns immutable domain capability identity records. It enforces duplicate capability rejection and one registered owner per domain.

`InterfaceOwnershipRegistry` owns interface ownership metadata. An interface id can have one owner capability in this layer, and duplicate interface ownership rejects before publication.

These registries publish copied inspection data only. They do not expose live implementation modules or direct runtime handles.
