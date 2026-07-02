# Security Audit Runtime

Audit records are inert records, not moderation logs.

This runtime records future audit schema shapes only. It does not collect analytics, send telemetry, monitor clients, write DataStores, report externally, ban, kick, moderate, or punish.

Audit schemas require `auditId`, `ownerSystem`, optional `schemaType = SecurityAuditSchema`, safe metadata, safe context, and safe tags.
