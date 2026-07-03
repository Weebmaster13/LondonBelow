# Asset Manifest Validation

Phase 45 defines the London Engine Asset Manifest Runtime Foundation. This is server-authoritative schema infrastructure only. It describes future asset definitions, categories, packages, references, variants, dependencies, ownership records, budget records, compatibility records, and audits without loading or executing any content.

## Hard Boundary

Asset definitions are records. Categories are taxonomy. Packages are manifest groups. References are symbolic, id, path, localization-key, package, or manifest records, not loaded assets. Variants are metadata. Dependencies are metadata, not loading order execution. Ownership records are documentation, not authority transfer. Budgets are declared constraints, not enforcement. Compatibility records are metadata, not migration or loading logic. Audits are review summaries, not enforcement.

The runtime does not own asset loading, asset preloading, ContentProvider execution, InsertService execution, MarketplaceService execution, animation loading, sound loading, model spawning, mesh insertion, texture application, material application, decal application, particle or VFX creation, UI creation, font loading, localization loading, Chapter content loading, content streaming, map loading, room loading, Workspace mutation, ReplicatedStorage mutation, ServerStorage mutation, remotes, client authority, runtime orchestration, gameplay execution, Presentation execution, Save execution, DataStore reads or writes, HttpService, MessagingService, analytics collection, telemetry sending, Chapter content, story, dialogue, or cutscenes.

## Runtime Shape

The implementation lives in `src/ServerScriptService/AssetManifest/Core`. `AssetManifestCoordinator` is the lifecycle facade registered by Bootstrap. Category facade modules expose narrow `register` methods. `AssetManifestState` owns bounded source-of-truth maps and a single global namespace across definitions, categories, packages, references, variants, dependencies, ownership records, budgets, compatibility records, and audits. `AssetManifestValidation` rejects malformed schemas, unsupported schema types and kinds, invalid references, self dependencies, direct dependency cycles, unsafe metadata, unsafe context, unsafe tags, forbidden markers, cyclic tables, Roblox Instances, functions, threads, userdata, oversized strings, oversized node counts, and deep payloads before mutation. `AssetManifestSerialization` deep-copies public outputs and sanitizes diagnostic payloads.

## Validation Coverage

Definition records validate domain, asset kind, category references, reference references, variant references, dependency references, and per-asset list limits. Package records validate package kind and package asset references. Reference records validate reference kind and owning asset. Variant records validate variant kind and owning asset. Dependency records validate source and target assets, reject self-dependencies, and reject direct cycles. Ownership, budget, compatibility, and audit records validate their ids, owning asset references, supported kinds, limits, and forbidden payloads.

## Diagnostics And Snapshots

Diagnostics are health-only. They expose lifecycle state, health, validation status, category counts, per-category limit usage, runtime limits, serialization posture, isolation proof, integrity posture, no-loading posture, no-execution posture, recent sanitized validation failures, and the last self-check result. Diagnostics do not monitor loaded assets, expose handles, mutate asset manifest state, or become loading/execution.

Snapshots are isolated deep copies of schema state only. They contain counts, schema records, integrity posture, validation failures, no-loading posture, and no-execution posture. They never contain live asset handles, ContentProvider handles, service references, remotes, Workspace references, loaded Instances, or execution adapters.

## Self-Check Certification

`AssetManifestSelfChecks` is pre-start certification. It proves malformed records reject, duplicate ids reject globally, unsupported types and kinds reject, invalid references reject, forbidden fields reject in keys and string values, serialization rejects unsafe runtime values, histories are bounded, category limits reject safely, snapshots are isolated, diagnostics are read-only copies, shutdown clears state and namespace data, and no loading or execution surface exists.

## Future Work Rules

Future systems may reference Asset Manifest schema ids. They must not treat asset definitions, references, packages, dependencies, budgets, compatibility records, or audits as commands. Any future asset loading, preloading, content streaming, or content application must be a separate governed runtime with its own contract, validation, diagnostics, snapshots, self-checks, security review, and production audit.

## Production Hardening Addendum

This runtime remains metadata-only. Validation rejects unsupported schema types and kinds, invalid references, global namespace collisions, unsafe metadata, unsafe context, unsafe tags, forbidden loading/execution markers, cyclic data, Roblox Instances, functions, threads, userdata, oversized strings, oversized node counts, deep payloads, and runtime/service/asset handles before mutation.

Every category shares one deterministic global namespace. Duplicate rejection occurs before state mutation and never evicts valid schema data. Runtime limits bound assets, categories, packages, references, variants, dependencies, ownership records, budget records, compatibility records, audits, validation failures, snapshot history, payload depth, payload node count, payload string length, tags, package assets, and audit findings.

Diagnostics are health-only and snapshots are schema-only deep copies. They certify no asset loading, no asset preloading, no ContentProvider execution, no InsertService execution, no MarketplaceService execution, no model spawning, no animation loading, no sound loading, no mesh loading, no texture loading, no material loading, no decal loading, no UI creation, no localization loading, no Workspace/ReplicatedStorage/ServerStorage mutation, no gameplay execution, no Presentation execution, no Save execution, no remotes, no client authority, no analytics collection, and no telemetry sending.
