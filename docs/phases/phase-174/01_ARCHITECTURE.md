# Phase 174 Architecture

`DialogueInteractionCoordinator` registers after `DialogueExecutionCoordinator` and before lobby/gameplay systems.

The runtime owns a bounded interaction coordination layer:

1. `RuntimeDialogueInteraction` receives server-authoritative interaction requests.
2. `InteractionSessionRegistry` records one immutable interaction session identity.
3. `PendingChoiceQueue` orders pending responses by priority and insertion order.
4. `InteractionValidator` validates responses before mutation.
5. `RuntimeEventCoordinator` records internal dialogue runtime event coordination evidence.

The runtime remains an integration layer. It does not create presentation, input, remotes, persistence, or gameplay outcomes.
