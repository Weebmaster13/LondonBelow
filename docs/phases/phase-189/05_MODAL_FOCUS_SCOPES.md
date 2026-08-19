# Phase 189 - Modal Focus Scopes

Accessibility metadata adds bounded `scopeId`, `modal`, `scopePriority`, and `initialFocus`. Visible modal containers compete by descending priority with stable node-ID ties. Only controls descended from the active modal are eligible for focus restoration or fallback. Outside controls become non-selectable, inactive, and non-interactable, and their queued activation rejects through an explicit scope fence. Duplicate modal scope IDs, focusable modal containers, invalid priority use, duplicate initial focus, and disabled initial focus reject before rendering.

## Ownership

Phase 189 owns deterministic modal focus containment inside runtime-owned GUI trees.

## Non-Ownership

It does not manage CoreGui, unrelated interfaces, camera modality, or gameplay pause state.

## Certification Boundary

Nested/layered modal containment and priority require Studio evidence.
