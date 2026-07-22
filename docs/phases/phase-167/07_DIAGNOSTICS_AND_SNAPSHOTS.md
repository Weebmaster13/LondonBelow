# Diagnostics And Snapshots

Diagnostics use provider `runtimeMessagingIntegration` and lowerCamelCase posture key `messagingIntegrationPosture`.

Diagnostics expose:

- consumer registry;
- consumer lifecycle;
- dependency graph;
- subscription registry;
- runtime discovery;
- integration metrics;
- integration profiler;
- integration budgets;
- immutable evidence;
- certification posture.

Snapshots expose isolated deep copies through snapshot provider `runtimeMessagingIntegration`.

Diagnostics and snapshots explicitly report no command ownership, no event ownership, no query ownership, no direct gameplay coupling, no networking, no persistence, no Workspace mutation, and no client authority.
