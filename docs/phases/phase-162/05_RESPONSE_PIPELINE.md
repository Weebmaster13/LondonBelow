# Response Pipeline

Persistence responses contain `success`, `provider`, `duration`, `result`, and `failureReason`.

The response pipeline validates provider responses before publication and records bounded response history. Failed responses require an explicit failure reason.
