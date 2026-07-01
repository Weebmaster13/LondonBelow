# Hypothesis Runtime

A hypothesis is a possible explanation.

## Purpose

Multiple hypotheses can coexist. A cognitive entity can believe the player made a sound, the Building made it, another entity moved, the sound was structural, or the source is unknown.

## Behavior

The runtime supports generation, confidence, ranking, contradiction hooks, archival hooks, and resurrection hooks. Phase 16 implements deterministic generation and ranking as the foundation.

## Boundary

Hypotheses do not directly influence gameplay. They are reasoning candidates only.
