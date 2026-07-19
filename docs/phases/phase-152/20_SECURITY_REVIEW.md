# Security Review

Phase 152 avoids shell interpolation for backend execution. Rojo place building uses direct arguments through existing command helpers.

Security controls:

- evidence import is constrained to `automation/local-state/runtime-execution`;
- user-profile paths are normalized before committed reporting;
- discovered executable paths are represented by normalized paths and identities;
- no arbitrary discovered executable is invoked;
- no MCP command is invoked;
- no credentials are committed;
- imported evidence cannot control command execution;
- certification fields cannot be mutated by imported evidence;
- no unrelated Studio processes are terminated.
