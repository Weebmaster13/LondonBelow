# Governance Inspection Runtime

`GovernanceInspectionRuntime` is the wrapper for `GovernanceInspection` records.

It forwards registration to `AssetGovernanceCertificationInspectionCoordinator.registerGovernanceInspection` and exposes coordinator inspection diagnostics. Inspection records describe copied health inspection metadata only. They do not inspect mutable subsystem state, repair records, authorize execution, schedule work, orchestrate systems, persist data, network, or mutate upstream runtimes.
