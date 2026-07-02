# Tool Definition Runtime

Tool definitions describe future internal tools as data.

Each definition must include:

- `toolId`
- `ownerSystem`
- optional `schemaType = "ToolDefinitionSchema"`
- safe `metadata`
- safe `context`
- safe `tags`

Tool definitions cannot contain executable callbacks, Roblox Instances, remotes, admin powers, remote console fields, Workspace references, DataStore operations, or client authority.

Registering a tool definition only records the schema. It does not enable the tool.
