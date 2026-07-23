# Phase 175 Architecture

`DialoguePresentationCoordinator` registers after `DialogueInteractionCoordinator` and before lobby/gameplay systems.

The runtime owns:

- presentation contract definitions
- presentation requests
- data-only descriptors
- acknowledgements
- synchronization metadata
- localization references
- accessibility metadata

It does not implement a Presentation Runtime, UI, rendering, audio, camera, input, networking, persistence, or client authority.
