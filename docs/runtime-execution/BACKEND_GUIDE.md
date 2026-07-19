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

Phase 151 does not implement launch behavior. A future backend may launch only when the repository has a supported execution method, source attribution is valid, the working tree is safe, and structured capture can preserve evidence without fabrication.
