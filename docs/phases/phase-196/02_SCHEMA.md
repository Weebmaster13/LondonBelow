# Phase 196 Schema

## Ownership

Composition records contain `schemaVersion`, `compositionId`, `targetRevision`, `rootComponentId`, and `components`. Components contain `componentId`, `kind`, `parentComponentId`, `props`, optional accessibility metadata, optional responsive metadata, and optional tags.

## Non-Ownership

The schema does not contain gameplay objectives, save payloads, remotes, arbitrary scripts, asset loading instructions, or server authority.

## Certification Boundary

Schema execution is valid only when the exact field set, supported kind, parent graph, and render-property allowlist all pass validation.
