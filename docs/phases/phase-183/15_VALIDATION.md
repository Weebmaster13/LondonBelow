# Validation

Validation is performed before mutation. It covers shape, exact fields,
identity, enum support, graph invariants, semantic roles, layout constraints,
responsive variants, style/theme/typography references, localization tokens,
accessibility metadata, asset reference syntax, bounded limits, unsafe payloads,
and revision expectations.

Rejected operations record evidence and increment failure posture without
mutating unrelated definitions, compositions, plans, bindings, or revisions.

Validation remains metadata-only and never resolves actual assets, translated
strings, Roblox services, client input, or GUI properties.
