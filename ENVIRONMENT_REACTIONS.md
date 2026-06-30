# Environment Reactions

Environment reactions are approval contracts, not final effects.

Each reaction definition includes:

- `id`
- `category`
- `displayName`
- `intensity`
- allowed pressure states
- global cooldown
- zone cooldown
- repeat limit
- solo/group support
- future approval requirements
- suppression rules
- tags
- execution kind
- puzzle/chase/release safety
- description

## Categories

The foundation supports fog, rain, wind, doors, props, rooms, streets, building attention, windows, carriage atmosphere, silence support, chase support, release support, puzzle pressure, and safe-room protection.

## Selection Rules

`EnvironmentReactionSelector` considers pressure state, party size, zone kind, preferred category, cooldowns, repeat limits, memory, and fairness. It can select no reaction when silence is stronger or safer.

## Anti-Spam Rules

Reactions have global and per-zone cooldowns. Memory tracks repeats, suppressed reactions, failed reactions, affected zones, and category counts. The Director should not slam doors or thicken fog every time an observation arrives.

Reaction definitions are validated for category, pressure states, execution kind, intensity, cooldowns, repeat limits, names, and descriptions. Invalid definitions fail validation instead of silently entering the Director.
