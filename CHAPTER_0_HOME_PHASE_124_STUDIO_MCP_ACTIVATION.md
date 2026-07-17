# Chapter 0 Home Phase 124 Studio MCP Capture Activation

Phase 124 attempts repository-supported Studio MCP structured capture activation.
It is infrastructure only and does not modify Chapter 0 gameplay, observation
facts, presentation, remotes, persistence, Monster AI, save execution, rendering,
combat, inventory, or Chapter 1 content.

## Activation Flow

```text
source attribution
-> clean tree and origin/main match
-> Studio installation discovery
-> official Studio MCP command detection
-> repository capture opt-in check
-> supported execution method check
-> supported structured result channel check
-> runner invocation only if all prerequisites pass
-> existing Phase 121 evidence transport
```

## MCP Ownership

The activation layer owns prerequisite evaluation and activation refusal. It does
not own certification validation or certification decisions.

Certification authority remains only:

- `Phase118CertificationContract.validateResult()`;
- `Phase118CertificationContract.canProductionCertify()`.

## Activation Prerequisites

All of these must be true before runner invocation:

- Studio installation is available;
- official Studio MCP command is available;
- repository capture opt-in is enabled;
- supported execution method exists;
- supported structured result channel exists;
- source attribution is valid;
- working tree is clean;
- local `HEAD` matches `origin/main`.

## Supported Activation States

- `activationReady`: every prerequisite is true and runner invocation may proceed
  through a documented capture channel.
- `executionBlocked`: one or more prerequisites are missing, so the runner is not
  invoked.

## Unsupported Activation States

The bridge refuses:

- MCP command presence without repository opt-in;
- launch-only Studio CLI as certification evidence;
- undocumented MCP commands;
- simulated capture;
- stdout scraping;
- manual result editing;
- synthesized runtime totals;
- runner invocation while source attribution is invalid.

## Current Result

On the current machine, Studio is installed and the official Studio MCP command is
present. Repository capture opt-in is not enabled and no supported structured
runner execution method is configured. The bridge therefore reports:

```text
status: executionBlocked
runnerInvoked: false
structuredResultCaptured: false
```

This is the correct result. No runtime execution or Production Certification is
claimed.
