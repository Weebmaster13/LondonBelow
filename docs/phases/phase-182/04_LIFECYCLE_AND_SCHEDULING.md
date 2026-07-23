# Lifecycle And Scheduling

Lifecycle states:

`Created -> Mapped -> Reserved -> Scheduled -> WaitingExecution -> Released -> Closed`

Terminal states:

- `Cancelled`
- `Expired`
- `Failed`

`RobloxRendererScheduling` records deterministic scheduling metadata with queue ordinal, runtime priority, scheduler ordinal, and dispatch eligibility. Scheduling does not dispatch visual work.
