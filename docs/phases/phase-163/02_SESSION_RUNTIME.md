# Session Runtime

`SaveSessionRuntime` owns open, close, cancel, recover, lock, transaction, and dirty coordination for save sessions.

Each session records `sessionId`, `saveId`, `state`, `provider`, `dirty`, `lockOwner`, `activeTransaction`, `retryCount`, `openedTimestamp`, `lastSave`, `lastLoad`, and `lastFailure`.
