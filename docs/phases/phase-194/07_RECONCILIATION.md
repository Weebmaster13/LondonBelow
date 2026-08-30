# Reconciliation
## Ownership
Every committed render, unmount, and shutdown clears active theme identity and advances the theme generation.
## Non-Ownership
Theme cleanup does not cancel animations or change localization catalogs.
## Certification Boundary
Evidence must show old theme identity cannot cross generations.
