# Presentation Routing Runtime

`PresentationRoutingRuntime` records future routing intent for approved presentation requests.

Routing records include:

- presentation id
- presentation type
- channels
- reason
- whether a future adapter would route it
- proof that no remote or presentation execution occurred

This runtime never sends data to clients.
