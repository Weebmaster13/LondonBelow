# Checkpoint Eligibility

Phase 160 introduces checkpoint eligibility metadata only.

`chapter0.objective.leaveHome` is marked checkpoint eligible after it becomes active. The runtime does not write saves, create profiles, call DataStore, persist progress, or make final Save Director decisions.

Phase 161 is expected to define the Save Runtime Foundation and persistent progress model that can consume this metadata.
