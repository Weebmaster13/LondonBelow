# Phase 186 - STAGING AND COMMIT.md

Every replacement tree is created detached. Properties are applied in sorted order, hierarchy is assembled off-screen, and only the complete root is mounted. The prior root is destroyed after the new root mounts successfully.

## Ownership

Phase 186 owns staging, property application, hierarchy assembly, commit ordering, and cleanup.

## Non-Ownership

Phase 186 does not own cross-frame animation, partial tree exposure, or direct mutation of unrelated PlayerGui children.

## Certification Boundary

Phase 186 is Production Candidate only. Phase 108 remains the latest Production Certified milestone until authoritative Roblox Studio Runtime Execution Framework evidence is imported and validated.
