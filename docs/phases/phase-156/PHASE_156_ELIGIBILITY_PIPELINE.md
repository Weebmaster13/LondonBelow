# Eligibility Pipeline

Eligibility checks validate request shape, replay id, rate window, known interaction, known target, status, target match, disabled eligibility, and contention.

Failures return explicit reason codes such as `UnknownInteraction`, `UnknownTarget`, `TargetMismatch`, `RateLimited`, `ContentionActive`, and `UnsafeRequest`.
