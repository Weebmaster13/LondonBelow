# Security Trust Policy Runtime

Trust policies are policy data, not live enforcement.

Trust policy schemas define the future shape of server-side trust rules. They do not approve client authority, inspect clients, punish users, or change gameplay behavior.

Trust policies require `trustPolicyId`, `ownerSystem`, optional `schemaType = SecurityTrustPolicySchema`, safe metadata, safe context, and safe tags.

Unsupported trust policy schema types, duplicate ids, unsafe payloads, forbidden enforcement fields, service references, callbacks, Roblox Instances, cycles, oversized payloads, and deep payloads reject before state changes. Trust policies cannot overlap ids with any other security category.
