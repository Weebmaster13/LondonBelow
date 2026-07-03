# Runtime Startup Plan Runtime

Startup plans are schemas, not startup commands.

Startup plans may reference only registered nodes, registered dependency records, and registered ordering records. Plan node, dependency, and ordering counts are bounded. Startup plans do not start runtimes, initialize modules, load modules, require modules, call Framework, replace Framework, or resolve services.
