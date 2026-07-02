# Security Authority Runtime

Authority rules describe future server authority boundaries.

They are schema records only. Clients cannot define trust policies, approve authority, or create security schemas through this runtime.

Authority rules require `authorityRuleId`, `ownerSystem`, optional `schemaType = SecurityAuthorityRuleSchema`, safe metadata, safe context, and safe tags.
