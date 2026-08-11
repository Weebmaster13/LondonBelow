# Node And Semantic Model

Nodes carry platform-independent meaning. Supported node kinds include Root,
Layer, Region, Container, Text, Image, Icon, Button, Choice, ChoiceGroup,
Progress, Divider, Spacer, ScrollRegion, ViewportPlaceholder, Composite, and
SemanticOnly.

Semantic roles describe intent: DialogueRoot, DialoguePanel, SpeakerName,
SpeakerPortrait, DialogueBody, ChoiceContainer, ChoiceItem,
ObjectiveContainer, ObjectiveTitle, ObjectiveProgress, InteractionPrompt,
NotificationContainer, CaptionContainer, SubtitleContainer, MenuRoot,
OverlayRoot, and Decorative.

Semantic validation prevents incompatible combinations. For example,
SpeakerPortrait must be image metadata. SemanticOnly nodes cannot claim asset
intent because they are structural meaning, not renderable content.
