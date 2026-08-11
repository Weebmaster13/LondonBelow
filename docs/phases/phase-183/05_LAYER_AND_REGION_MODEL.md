# Layer And Region Model

Layers describe logical presentation order, not Roblox ZIndex. Phase 183
supports WorldPresentation, HUD, Interaction, Dialogue, Cinematic, Overlay,
CriticalNotification, and Debug.

Regions describe semantic placement areas such as dialogue-safe areas, HUD
areas, lower-third regions, overlays, and other future screen regions. Phase
183 records region metadata only and does not measure a viewport or mutate any
GUI property.

The compiler extracts layers and regions from nodes into deterministic plan
sections so future execution phases can consume them without traversing raw
authoring data.
