# Validation

Required validation for Phase 158:
- JavaScript syntax checks for automation modules;
- `stylua src`;
- `stylua --check src`;
- `selene src`;
- `rojo sourcemap default.project.json --output sourcemap.json`;
- `rojo build default.project.json --output rojo-verify.rbxlx`;
- `npm run london:status`;
- `npm run london:check`;
- `npm run london:phase158:selfcheck`;
- Phase 156 and Phase 157 regression self-checks;
- forbidden API scan over Phase 158 delta;
- `git diff --check`;
- generated artifact cleanup.
