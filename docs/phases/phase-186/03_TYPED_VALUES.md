# Phase 186 - TYPED VALUES.md

The decoder supports finite scalars, explicit Enum.Type.Item values, Color3, Vector2, UDim, UDim2, Rect, asset references, NumberSequence, and ColorSequence. Unsupported structured values fail closed.

## Ownership

Phase 186 owns deterministic conversion from Phase 185 descriptors to Roblox property values.

## Non-Ownership

Phase 186 does not own asset downloading, localization resolution, arbitrary constructors, functions, or executable values.

## Certification Boundary

Phase 186 is Production Candidate only. Phase 108 remains the latest Production Certified milestone until authoritative Roblox Studio Runtime Execution Framework evidence is imported and validated.
