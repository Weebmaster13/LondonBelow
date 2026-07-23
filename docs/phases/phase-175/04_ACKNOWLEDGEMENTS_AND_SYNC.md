# Acknowledgements And Synchronization

Acknowledgements are immutable metadata records from a future presentation consumer.

They must match presentation id and execution id ownership. Duplicate acknowledgement ids reject. Unsupported acknowledgement kinds reject.

Synchronization policies are explicit: `NoWait`, `WaitForAccepted`, `WaitForStarted`, `WaitForCompleted`, `WaitForCancelled`, and `WaitForTerminalState`.

Synchronization resolution returns metadata only and does not resume Dialogue Execution directly.
