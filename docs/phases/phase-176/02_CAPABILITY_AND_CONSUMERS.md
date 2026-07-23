# Capability And Consumers

`PresentationCapabilityRegistry` stores immutable capability identity.

`PresentationConsumerRegistry` stores server-authoritative consumer metadata: consumer id, runtime capability, supported presentation kinds, contract version, status, and registration ordinal.

Consumers may receive metadata and produce acknowledgements. They cannot mutate dialogue, workflow, execution, or contracts.
