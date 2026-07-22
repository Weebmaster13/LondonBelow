# Dirty Tracking

Dirty tracking supports `MarkDirty`, `MarkClean`, and `IsDirty`.

Save Runtime marks sessions dirty. Persistence Runtime clears dirty after successful save. Save Session Runtime coordinates the flag and does not serialize or store payloads.
