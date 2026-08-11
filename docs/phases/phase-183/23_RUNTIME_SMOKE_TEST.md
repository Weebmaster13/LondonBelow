# Runtime Smoke Test

Static validation and automation self-checks can pass in this repository, but
they are not authoritative Roblox Studio runtime evidence.

The Phase 183 runtime wrapper writes
`automation/runtime-evidence/phase-183/phase-183-runtime-report.md` and reports
`executionBlocked` when authoritative Roblox Studio evidence has not been
imported through the Runtime Execution Framework.

This blocked status is expected on machines without the supported Studio
runtime evidence path. It prevents false Production Certification.
