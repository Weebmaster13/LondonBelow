# Runtime Execution Framework Developer Guide

Use the framework through the coordinator or exported module API:

```powershell
npm run london:runtime-execution
npm run london:runtime-execution:selfcheck
```

The normal coordinator output is intentionally `executionBlocked` in Phase 151. That is correct: the framework can create a session, manifest, capability report, assertion report, cleanup record, and summary, but no backend is authorized to launch Studio or claim runtime evidence.

Future runtime phases should import from `automation/runtime-execution/index.mjs` instead of creating another one-off execution script.

Allowed extension points:

- add a backend contract to the registry;
- add capability probes owned by that backend;
- add runner launch logic behind a supported backend;
- forward structured runtime evidence into the existing evidence/certification pipeline;
- preserve the framework session and evidence category schemas.

Disallowed extension points:

- duplicating certification decisions;
- scraping runtime output into fabricated evidence;
- mixing static/build/runtime/manual/certification evidence;
- launching Studio from an unsupported or undocumented interface;
- changing gameplay to satisfy automation.
