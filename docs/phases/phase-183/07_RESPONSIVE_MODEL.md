# Responsive Model

Responsive metadata prepares future visual execution for Compact, Standard,
Wide, UltraWide, KeyboardMouse, Gamepad, Touch, and Unknown contexts.

Phase 183 does not query device state. It stores and validates authored variant
intent only. Variant keys must be canonical and remain bounded by
`Types.VisualCompositionLimits.MaxResponsiveVariants`.

This keeps responsive behavior deterministic and renderer-independent until a
future client-facing runtime has authority to evaluate actual device conditions.
