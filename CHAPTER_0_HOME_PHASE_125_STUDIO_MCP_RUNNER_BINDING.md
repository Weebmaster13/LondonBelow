# Chapter 0 Home Phase 125 Studio MCP Runner Command Binding

Phase 125 attempts to bind the existing Studio automation bridge to a documented
Roblox Studio MCP runner command. It is infrastructure only and does not modify
Chapter 0 gameplay, observation facts, presentation, remotes, persistence, Monster
AI, save execution, rendering, combat, inventory, or Chapter 1 content.

## Binding Architecture

```text
source attribution
-> Studio discovery
-> official MCP command detection
-> repository capture opt-in
-> connected Studio MCP session discovery
-> documented runner command discovery
-> binding validation
-> runner invocation only if binding is available
-> existing Phase 121 evidence transport
```

The binding layer only discovers and validates a command binding. It does not
invent MCP commands, simulate Studio execution, scrape stdout, or synthesize
runtime data.

## Supported Bindings

A binding is supported only when all of these are true:

- a connected Studio MCP session is available;
- that session exposes a documented runner command;
- the command targets `Phase118CertificationRunner`;
- source attribution is valid;
- repository configuration explicitly opts in.

## Unsupported Bindings

Unsupported bindings are refused:

- no connected Studio MCP session;
- no documented runner command;
- configured command that does not target the Phase 118 runner;
- undocumented MCP command names;
- manual result editing;
- stdout scraping;
- simulated Studio execution.

## Current Result

No connected Studio MCP session exposes a documented command for invoking:

```text
ServerScriptService.Chapter0Home.Studio.Phase118CertificationRunner
```

The bridge therefore reports:

```text
status: executionBlocked
runnerInvoked: false
structuredResultCaptured: false
```

This limitation is external to the repository. No runtime evidence is fabricated
and no Production Certification is claimed.
