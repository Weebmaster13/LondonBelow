# Chapter 0 Home Phase 122 Studio Automation Execution Bridge

Phase 122 adds the Studio automation bridge that sits between the local capture
command and Roblox Studio. It is infrastructure only and does not change Chapter 0
gameplay, observation facts, presentation, remotes, persistence, Monster AI, save
execution, rendering, combat, inventory, or Chapter 1 content.

## Ownership

The bridge owns:

- Roblox Studio installation discovery;
- Studio version identifier detection from local install paths;
- supported execution method classification;
- launch request validation;
- bridge status and exit-code forwarding;
- deterministic bridge diagnostics;
- preservation of source attribution from the capture pipeline.

The bridge does not own:

- certification result validation;
- production-certification decisions;
- gameplay state;
- Studio runner implementation;
- manual result editing;
- invented or unsupported Roblox APIs.

Certification authority remains single-sourced in:

- `Phase118CertificationContract.validateResult()`;
- `Phase118CertificationContract.canProductionCertify()`.

## Commands

```powershell
npm run london:studio:bridge:phase120
npm run london:studio:bridge:phase120:selfcheck
npm run london:certify:phase120
```

`npm run london:certify:phase120` reuses the bridge and writes the existing Phase
121 JSON and Markdown evidence format. No new evidence format is introduced.

## Supported Execution Paths

The bridge supports deterministic discovery of Roblox Studio installations through:

- configured executable paths in `automation/config/automation-config.json`;
- `RobloxStudioBeta` on `PATH`;
- `RobloxStudioLauncherBeta` on `PATH`;
- Windows local Roblox version folders under `%LOCALAPPDATA%\Roblox\Versions`.

The bridge recognizes Studio CLI launch capability as launch-only. It does not
treat launch-only CLI support as certification execution because it does not
provide repository-supported structured runner result capture.

## Unsupported Execution Paths

The bridge rejects:

- simulated Studio execution;
- manual result editing;
- unsupported headless assumptions;
- alternate certification logic;
- runner replacement;
- result capture without source attribution;
- launch-only Studio CLI paths as certification evidence.

## Current Platform Result

On the current Windows machine, Studio is discoverable from the local Roblox
Versions folder. No supported non-interactive runner invocation and structured
result capture method is configured, so the bridge returns:

```text
status: executionBlocked
exitCode: 2
runnerInvoked: false
structuredResultCaptured: false
```

This is the correct outcome until a repository-supported Studio execution API is
available.

## Diagnostics

Bridge diagnostics include:

- bridge id;
- status;
- exit code;
- discovered installations;
- version identifiers;
- execution methods;
- selected method;
- runner invocation posture;
- structured result capture posture;
- next action.

These diagnostics are local tooling diagnostics only.
