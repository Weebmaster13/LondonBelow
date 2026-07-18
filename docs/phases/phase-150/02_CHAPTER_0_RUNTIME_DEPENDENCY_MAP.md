# Chapter 0 Runtime Dependency Map

Chapter0HomeCoordinator depends on Core Diagnostics, EventBus, Logger, SnapshotManager, Interaction feedback, Observation signals, Chapter0Home config/state/validation/serialization/diagnostics/snapshots, Players, Workspace, and CollectionService. Bootstrap registers Chapter0HomeCoordinator after Observation, PlayerExperience, Interaction, World, Objective, Narrative, and Presentation. Runtime prerequisites are present in source, but Studio-created player/client state remains unverified.
