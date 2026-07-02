# Story Gates

Story gates are reusable server-owned eligibility schemas.

They can express future requirements such as journal schema unlocks, memory fragment schema unlocks, identity thresholds, or gameplay schema state. They do not execute story, UI, effects, cutscenes, or Chapter content.

## Rules

- Gate IDs must be unique.
- Invalid gates reject.
- Duplicate gates reject.
- Requirements must be serializable and safe.