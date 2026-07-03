# Schedule Window Runtime

Windows are eligibility descriptions, not live time checks.

Window records describe always-open, runtime-phase, lifecycle, time-schema, budget, or future window policy data. They do not check clocks, open gates, close gates, or run scheduling logic.

Windows reject unsupported window kinds, unsafe payloads, and live scheduling markers.

## Hardening Rules

Windows reject live time checks, timer execution, execution gates, RunService, task handles, timer handles, callbacks, and execution adapters. Windows describe eligibility only; they do not open or close anything at runtime.
