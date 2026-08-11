# Layout Model

Layout metadata expresses intent. Supported layout modes include
AbsoluteIntent, AnchorIntent, FlowVertical, FlowHorizontal, GridIntent, Stack,
Overlay, Fill, ContentSized, AspectBound, and ResponsiveContainer.

Constraints are metadata. The runtime validates non-negative dimensions,
minimum and maximum ranges, and positive aspect ratio values. It rejects
impossible size ranges such as minimum width exceeding maximum width.

No Roblox layout objects are created. No Roblox properties are assigned. Future
execution phases translate these intents into platform operations.
