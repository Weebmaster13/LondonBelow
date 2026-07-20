# Network Contract

Phase 156 creates no new RemoteEvents or RemoteFunctions. Existing PlayerExperience remotes remain the network boundary:

- `RequestInteraction`
- `RequestFocus`
- `InteractionResult`
- `FocusUpdated`
- `Feedback`

Clients request; servers validate and decide.
