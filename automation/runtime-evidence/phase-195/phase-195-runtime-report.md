# Phase 195 Runtime Report

Static checks: 351/351 passed.

Regression checks: Phase 194 301/301, Phase 193 322/322, Phase 192 278/278, Phase 191 276/276, Phase 190 219/219, Phase 189 167/167, Phase 188 120/120, Phase 187 86/86, Phase 186 94/94, Phase 185 72/72, Phase 184 209/209.

Combined Phase 184–195: 2,495/2,495 passed.

Validation completed locally: Node syntax, architecture generate/check, git diff check, and Phase 195 forbidden executable-surface assertions passed. Architecture contains 116 contracts and 96 Bootstrap registrations. StyLua, Selene, and Rojo binaries were unavailable in this workspace and are not claimed.

Forbidden executable-surface assertions reject remotes, server invocation, DataStore, HTTP, Workspace service access, analytics, telemetry, frame loops, and dynamic code loading. The hardening uses only local `os.clock`, exact runtime-owned GUI property reads/writes, and bounded in-memory state.

Runtime: `executionBlocked`.

The strict importer requires an exact 72-case authoritative Roblox Studio result with phase 195, `authoritative: true`, a non-empty Studio run ID, and every named case passed. No Studio result was imported. Phase 108 remains the latest Production Certified milestone.
