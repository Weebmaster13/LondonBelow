# Governance Inspection Runtime

`GovernanceInspectionRuntime` is the wrapper for `GovernanceInspection` records.

It forwards registration to `AssetGovernanceCertificationInspectionCoordinator.registerGovernanceInspection` and exposes coordinator inspection diagnostics. It does not inspect mutable subsystem state, repair records, authorize execution, or mutate upstream runtimes.
