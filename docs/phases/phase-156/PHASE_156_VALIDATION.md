# Validation

Required validation:

- node --check automation modules
- npm run london:phase156:selfcheck
- npm run london:interaction-runtime:validate
- stylua src
- stylua --check src
- selene src
- rojo sourcemap
- rojo build
- git diff --check
- npm run london:status
- npm run london:check
- architecture, docs, contracts, and forbidden-surface scans
