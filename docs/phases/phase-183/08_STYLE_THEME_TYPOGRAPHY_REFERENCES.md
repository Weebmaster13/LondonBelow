# Style Theme Typography References

Phase 183 stores references, not rendered values. Theme references must use the
`theme.` namespace. Typography references must use the `type.` namespace. Style
references are semantic identifiers such as `dialogue.body` or
`choice.normal`.

The runtime does not resolve colors, fonts, sizes, strokes, gradients, images,
or Roblox text properties. Resolution belongs to later visual execution and
instance phases.

This separation lets Dialogue, HUD, menus, prompts, and overlays share stable
semantic presentation contracts before concrete Roblox rendering exists.
