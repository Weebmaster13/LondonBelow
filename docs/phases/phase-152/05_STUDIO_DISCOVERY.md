# Studio Discovery

Phase 152 adds `StudioDiscovery.mjs`.

Discovery checks configured Studio executable paths, PATH entries, and Windows Roblox version directories without hardcoding the user's name. Discovered paths are normalized before committed reporting and identified by short hashes rather than personal absolute paths.

Discovery distinguishes:

- detected installation;
- executable identity;
- launchable executable;
- Play/Run capability;
- structured capture capability;
- MCP command presence;
- repository MCP opt-in.

Studio discovery is installation evidence only. It is not runtime evidence.
