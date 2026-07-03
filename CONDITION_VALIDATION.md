# Condition Validation

Condition validation rejects malformed schemas, duplicate ids, unsupported schema types, unsupported domains, unsupported operators, unsupported group types, unsupported outcome kinds, invalid references, self dependencies, direct dependency cycles, oversized arrays, unsafe metadata, unsafe context, unsafe tags, oversized payloads, oversized strings, deep payloads, cyclic tables, Roblox Instances, functions, threads, and userdata.

Validation also rejects fields that imply evaluation, execution, rule execution, trigger execution, gameplay execution, client authority, remotes, Roblox service access, Workspace mutation, analytics, telemetry, Chapter content, story, dialogue, or cutscenes.

Duplicate rejection happens before mutation through a single global namespace shared by definitions, categories, expressions, operands, operators, groups, dependencies, states, outcomes, and audits.
