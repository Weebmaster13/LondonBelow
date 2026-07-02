# Interaction Registration Runtime

`InteractionRegistrationRuntime` validates and records interaction object schemas.

Duplicate ids reject. Unsupported types reject. Missing physical object ids reject. Unsafe eligibility, metadata, context, cooldowns, locks, tags, and ownership fields reject before state changes.

Registration does not execute an interaction.
