# Phase 196 Rendering Bridge

## Ownership

`RobloxGuiComponentRuntime.compose` compiles a component composition into a render contract and calls `RobloxGuiRenderingRuntime.render`. `RobloxGuiRenderingRuntime.renderComposition` exposes the bridge for consumers.

## Non-Ownership

The bridge does not bypass render transactions, reconciliation, localization, interaction, animation, theming, or integrity checks.

## Certification Boundary

The bridge is a client presentation path only. Authoritative Studio execution is still required for Production Certification.
