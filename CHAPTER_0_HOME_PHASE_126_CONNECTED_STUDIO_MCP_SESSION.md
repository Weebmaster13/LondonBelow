# Chapter 0 Home Phase 126 Connected Studio MCP Session Validation

Phase 126 adds a single repository authority for validating whether a real
connected Roblox Studio MCP session is visible to the automation environment. It
is infrastructure only and does not modify Chapter 0 gameplay, observation facts,
presentation, remotes, persistence, Monster AI, save execution, rendering, combat,
inventory, or Chapter 1 content.

## Session Authority

`automation/studio-session-authority.mjs` owns connected-session classification.
It exposes these stable states:

- `connected`
- `disconnected`
- `unsupported`
- `blocked`
- `unknown`

It also exposes health classifications:

- `Healthy`
- `Degraded`
- `Unavailable`
- `Disconnected`
- `Expired`
- `Blocked`
- `Unknown`

The authority never infers connectivity from Roblox Studio installation,
available MCP command names, or repository configuration alone. A session is
connected only when immutable session identity is visible from the runtime surface.

## Failure Reasons

The authority reports deterministic failure reasons:

- `SESSION_NOT_FOUND`
- `SESSION_UNSUPPORTED`
- `SESSION_DISCONNECTED`
- `SESSION_AUTH_FAILED`
- `SESSION_PROTOCOL_UNKNOWN`
- `SESSION_HEARTBEAT_TIMEOUT`
- `SESSION_PERMISSION_DENIED`
- `SESSION_NOT_VISIBLE`
- `SESSION_UNKNOWN`

## Bridge Integration

The Phase 122 Studio automation bridge consumes the session authority before any
future runner invocation. Phase 125 runner binding now requires both a documented
runner command and a connected Studio MCP session. Configured command names or MCP
binary availability cannot make the bridge binding-ready by themselves.

## Current Result

No connected Studio MCP session identity is exposed to this repository automation
environment. The authority reports:

```text
status: executionBlocked
sessionState: disconnected
health: Disconnected
failureReason: SESSION_NOT_VISIBLE
```

The bridge does not invoke `Phase118CertificationRunner`, does not synthesize
runtime evidence, and does not claim Production Certification.

## Ownership

The authority owns session discovery, identity validation, state classification,
health classification, transition evidence, stable exit codes, and bridge-facing
diagnostics.

It does not own certification decisions, Studio runner execution, gameplay,
networking, persistence, analytics, telemetry, remotes, rendering, save runtime,
or Chapter content.

## Commands

```powershell
npm run london:studio:session:phase120
npm run london:studio:session:phase120:selfcheck
```

Exit code `0` means a supported healthy connected Studio MCP session is visible.
Exit code `2` means execution remains blocked by missing or unsupported session
availability. Exit code `7` means source attribution is invalid.
