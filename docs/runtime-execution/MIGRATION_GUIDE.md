# Runtime Execution Framework Migration Guide

Every future runtime validation phase should consume `automation/runtime-execution` as the execution authority.

Migration requirements:

- create an execution configuration;
- use the registry to select a backend;
- resolve capabilities before launch;
- create a session and manifest before runtime execution;
- keep evidence categories separated;
- write assertions through the framework vocabulary;
- route cleanup and history through the framework;
- defer certification decisions to the existing certification authority.

Existing Phase 120 through Phase 150 Studio tooling remains intact. Phase 152 integrates the existing bridge read-only and exposes backend contracts so future phases can migrate deliberately.
