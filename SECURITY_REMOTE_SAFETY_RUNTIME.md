# Security Remote Safety Runtime

Remote safety contracts are schemas, not remotes.

This runtime does not create `RemoteEvent` or `RemoteFunction` instances, connect handlers, fire clients, invoke clients, or route networking. It only records future remote safety contract shapes.

Remote safety schemas require `remoteSafetyId`, `ownerSystem`, optional `schemaType = SecurityRemoteSafetySchema`, safe metadata, safe context, and safe tags.
