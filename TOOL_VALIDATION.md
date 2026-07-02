# Tool Validation

Developer Tooling validation rejects malformed records, unsupported schema types, duplicate ids across one global schema namespace, unsafe payloads, unsafe tags, Roblox Instances, functions, threads, userdata, cycles, oversized payloads, and deep payloads.

It also rejects:

- Command execution fields
- Admin power fields
- Remote console fields
- Moderation fields
- Analytics collection fields
- Exploit and backdoor fields
- DataStore fields
- Workspace fields
- Remote and client fields
- Teleport, gameplay execution, and save mutation fields
- Chapter, story, dialogue, and cutscene fields

Validation is defensive and schema-only. It never executes tools, commands, admin powers, moderation actions, analytics collection, DataStore access, Workspace mutation, remotes, client authority, or Chapter content.

## Boundary Rules

- Tool records must use `ToolDefinitionSchema` when a schema type is present.
- Inspection records must use `InspectionRequestSchema` when a schema type is present.
- Command records must use `CommandSchema` when a schema type is present.
- Report records must use `ReportPackageSchema` when a schema type is present.
- Permission records must use `PermissionSchema` when a schema type is present.
- Audit records must use `AuditRecordSchema` when a schema type is present.
- Tool, inspection, command, report, permission, and audit ids may not overlap.

Validation diagnostics are sanitized. They must never expose raw Roblox Instances, functions, threads, userdata, cyclic references, or oversized payloads.
