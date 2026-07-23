# Negotiation

`RobloxCapabilityNegotiation` evaluates compatibility between a Roblox renderer and a rendering contract request.

Negotiation checks:

- renderer id
- contract version
- descriptor version
- rendering kind
- synchronization policy
- feature availability
- Roblox platform identity

Results are immutable compatibility metadata. Negotiation does not render, instantiate GUI, load assets, manipulate cameras, play animations, play sounds, network, persist, or mutate Workspace.
