# Environment Zones

Environment zones are a foundation API for future Studio-authored areas. This phase does not create maps or physical zone parts.

Supported zone kinds:

- `Street`
- `Alley`
- `Lobby`
- `Carriage`
- `Foyer`
- `Hallway`
- `PuzzleRoom`
- `SafeRoom`
- `ChaseRoute`
- `Exterior`
- `Interior`
- `Unknown`

`EnvironmentZoneContext` can register future zones and derive zone context from observations or Director requests. Unknown or missing data falls back to `unknown` and `Unknown` so the server never crashes on incomplete chapter setup.

Safe rooms prefer release and protection. Puzzle rooms suppress unfair obstruction. Chase routes allow support only when it improves readability and does not cheat the escape.
