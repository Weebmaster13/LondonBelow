# Runtime Execution Framework Backend Guide

Backends are interchangeable contracts. Phase 151 registers these backend kinds:

- StudioManual
- StudioMCP
- FutureRobloxCLI
- FutureHeadless
- FutureQARunner
- FutureCertificationRunner
- FutureMultiplayerRunner

A backend contract must declare:

- `backendId`
- `backendKind`
- `availability`
- `canLaunch`
- `canCaptureStructuredResults`
- `canReplay`
- `requiresHuman`
- `reason`

Supported availability values are `available`, `unsupported`, `blocked`, and `unknown`.

Phase 152 implements the first backend modules.

Use:

```powershell
npm run london:runtime-execution:backends
npm run london:studio-backend:manual
```

The manual backend is available and source-bound. Studio bridge and MCP backends are registered but blocked. A future backend may launch only when the repository has a supported execution method, source attribution is valid, the working tree is safe, and structured capture can preserve evidence without fabrication.
