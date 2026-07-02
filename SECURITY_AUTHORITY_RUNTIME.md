# Security Authority Runtime

Authority rules describe future server authority boundaries.

They are schema records only. Clients cannot define trust policies, approve authority, or create security schemas through this runtime.

Authority rules require `authorityRuleId`, `ownerSystem`, optional `schemaType = SecurityAuthorityRuleSchema`, safe metadata, safe context, and safe tags.

Authority rules do not grant authority. They describe future server-owned authority constraints only. Unsupported schema types, duplicate ids, unsafe payloads, forbidden client authority fields, and unsafe runtime values reject before state changes.
