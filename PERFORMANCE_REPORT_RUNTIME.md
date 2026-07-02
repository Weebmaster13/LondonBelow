# Performance Report Runtime

Report schemas describe the future shape of performance budget reports.

Reports are schema records only. They do not collect analytics, send telemetry, read platform services, monitor clients, or submit external reports.

This boundary lets London Engine define report structure before real profiling or telemetry exists, keeping future production tooling consistent with the Engine Constitution.
