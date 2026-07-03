# Runtime Startup Plan Runtime

Startup plans are schemas, not startup commands.

Startup plans may reference only registered nodes, registered dependency records, and registered ordering records. Plan node, dependency, and ordering counts are bounded. Startup plans do not start runtimes, initialize modules, load modules, require modules, call Framework, replace Framework, or resolve services.

Certified startup plans reject oversized node/dependency/ordering lists, startup execution payloads, initialization payloads, Framework mutation payloads, module loading payloads, require-call payloads, and service resolution payloads.
