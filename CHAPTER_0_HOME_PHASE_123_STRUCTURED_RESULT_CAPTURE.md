# Chapter 0 Home Phase 123 Studio Structured Result Capture Integration

Phase 123 integrates structured-result capture detection into the existing Studio
automation bridge. It is infrastructure only and does not change Chapter 0
gameplay, observation facts, presentation, remotes, persistence, Monster AI, save
execution, rendering, combat, inventory, or Chapter 1 content.

## Capture Architecture

The capture path remains:

```text
source attribution
-> Studio discovery
-> execution method classification
-> structured capture method detection
-> captured result envelope validation
-> Phase 121 JSON/Markdown evidence transport
-> stable exit code
```

The bridge does not replace or duplicate:

- `Phase118CertificationRunner`;
- `Phase118CertificationContract`;
- `Chapter0HomeStudioSelfCheckRunner`.

Certification authority remains only:

- `Phase118CertificationContract.validateResult()`;
- `Phase118CertificationContract.canProductionCertify()`.

## Supported Capture Paths

The bridge recognizes the official Roblox Studio MCP command when present:

- Windows: `%LOCALAPPDATA%\Roblox\mcp.bat`;
- macOS: `/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`.

The repository must explicitly enable a structured capture method in
`automation/config/automation-config.json` before the bridge may attempt capture.
Presence of the MCP command alone is not enough to certify runtime execution.

## Unsupported Capture Paths

Unsupported paths remain blocked:

- launch-only Studio CLI;
- simulated Studio execution;
- manual result editing;
- stdout scraping without a structured runner result;
- alternate certification logic;
- generated or synthesized runtime totals;
- MCP command presence without repository configuration.

## Captured Result Envelope

The bridge validates the transport envelope for these fields before forwarding:

- `schemaVersion`;
- `phase`;
- `runnerId`;
- `runtime`;
- `status`;
- `setupStatus`;
- `assertionStatus`;
- `cleanupStatus`;
- `upstreamStatus`;
- `executedSuites`;
- `skippedSuites`;
- `warnings`;
- `failures`;
- `productionCertified`;
- `exactSourceCommit`;
- `evidenceId`;
- `captureTimestamp`;
- `nextAction`.

This is transport validation only. The authoritative schema validation still
belongs to `Phase118CertificationContract.validateResult()`.

## Current Platform Result

On the current machine, Studio is detected and Studio CLI launch is classified.
No repository-enabled official structured capture method is available, so the
bridge returns:

```text
status: executionBlocked
exitCode: 2
runnerInvoked: false
structuredResultCaptured: false
```

No runtime evidence is fabricated and no Production Certification is claimed.
