# Reset Orchestration

`Chapter0EnvironmentalCoordinator.resetFixtures()` resets Chapter 0 environmental bindings by unregistering catalog fixtures from the Environmental Interaction Runtime and clearing Chapter 0 binding state.

Reset is deterministic and idempotent. It does not perform save writes, Workspace mutation, or Chapter progression.
