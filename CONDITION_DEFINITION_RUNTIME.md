# Condition Definition Runtime

Condition definitions are inert records that describe a future condition by id, name, domain, owner system, optional related categories, expressions, dependencies, outcomes, metadata, context, and tags.

Definitions do not evaluate player state, gameplay facts, narrative gates, objective progress, puzzle progress, monster state, presentation state, or rule outcomes. They only provide stable schema references that future governed systems may inspect.

Validation requires stable ids, supported domains, safe metadata/context/tags, registered references, bounded arrays, and global id uniqueness.
