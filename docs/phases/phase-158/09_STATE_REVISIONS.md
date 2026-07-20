# State Revisions

Environmental state commits now compare expected state and revision before mutation.

Rejected outcomes:
- `STATE_REVISION_MISMATCH`
- `TRANSITION_SUPERSEDED`

Duplicate completed requests return the previous completion result without reapplying mutation.
