# Content Category Runtime

Categories group content definitions by policy, owner, or future tooling need.

Categories are schema records only. They may declare allowed content domains, descriptive metadata, and tags. They cannot perform loading, streaming, spawning, UI rendering, or gameplay execution.

Category ids share the global Content Registry namespace. A category id cannot collide with a content definition, reference, dependency, package, version, or tag id.

Future tools should use categories for organization and review surfaces, not as authority to execute content.

## Hardening Notes

Categories are classification schemas, not loaded content. A category can help future tools group definitions, but it cannot carry authoring tools, loader configuration, asset bundle data, runtime object references, client authority, analytics collection, telemetry sending, or Chapter content.
