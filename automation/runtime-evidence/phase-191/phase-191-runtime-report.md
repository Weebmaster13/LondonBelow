# Phase 191 Runtime Report

Static checks: 276/276 passed.

Regression checks: Phase 190 219/219, Phase 189 167/167, Phase 188 120/120, Phase 187 86/86, Phase 186 94/94, Phase 185 72/72, Phase 184 209/209.

Combined Phase 184–191: 1,243/1,243 passed.

Validation: Node syntax, StyLua formatting/check, Rojo sourcemap/build, architecture catalog, git diff check, and forbidden executable-surface scan passed. Architecture contains 112 contracts and 96 Bootstrap registrations. Selene was attempted, but its Roblox standard-library API dump could not be collected in this environment; a Selene pass is not claimed locally.

Runtime: `executionBlocked`.

The strict importer requires an exact 38-case authoritative Roblox Studio result. No Phase 191 Studio result was imported, so no runtime success or Production Certification is claimed. Phase 108 remains the latest Production Certified milestone.
