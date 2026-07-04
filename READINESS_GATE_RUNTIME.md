# Readiness Gate Runtime

`ReadinessGate` records whether a named metadata gate passed for a checklist.

Fields:

- `gateId`
- `checklistId`
- `gateKind`
- `required`
- `passed`
- `reason`
- `tags`
- `metadata`

Gates are evidence records. They are not executable guards and do not start asset loading or streaming.
