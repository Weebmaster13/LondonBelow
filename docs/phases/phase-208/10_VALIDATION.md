# Phase 208 Validation

Required validation:

* node syntax checks
* changed Lua StyLua formatting
* `stylua --check src`
* `selene src`
* Rojo sourcemap
* Rojo build
* architecture check
* Phase 208 self-check
* Phase 207 and Phase 206 regression self-checks
* forbidden surface scan
* `git diff --check`
* `npm run london:status`
* `npm run london:check`

Final command evidence is recorded in `automation/runtime-evidence/phase-208`.
