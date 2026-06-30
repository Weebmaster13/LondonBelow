# London Below Code Style

## Luau Style

- Format with StyLua.
- Lint with Selene.
- Use tabs, Unix line endings, and the repository `stylua.toml`.
- Prefer clear names over abbreviations.
- Keep modules small enough to understand in one pass.

## Module Shape

- ModuleScripts should return a table unless a different pattern is clearly justified.
- Public APIs should be explicit and stable.
- Constructors should validate required dependencies.
- Avoid hidden global state.
- Prefer config-driven tuning over hard-coded numbers.

## Error Handling

- Validate all external input.
- Fail fast during startup when required dependencies are missing.
- Fail safely during runtime when players disconnect, assets are missing, pathfinding fails, remotes are malformed, or DataStore calls fail.
- Log recoverable failures with enough context to debug them.

## Logging

Every production system should have a scoped logger.

Log:

- Startup and shutdown.
- Important state transitions.
- Remote validation failures.
- Missing configuration.
- Failed service calls.
- Unexpected but recoverable errors.

Do not spam logs every frame.

## Multiplayer Safety

- The server owns gameplay truth.
- Clients may request actions, but servers decide outcomes.
- Remotes must validate payload type, player state, distance/proximity, cooldowns, and authorization.
- Design for late join, disconnect, death, respawn, and party membership changes.

## Anti-Patterns

- God scripts.
- One-off local-player-only logic in production systems.
- Monster AI that directly mutates objective state.
- UI code that decides authoritative progress.
- Random jumpscare scripts outside the Horror Director.
- Remotes with vague names like `DoThing` or `Update`.
