# Bootstrap

Bootstrap runtime validation requires imported Studio result evidence.

Until evidence is imported, these are blocked:

- server startup
- client startup
- bootstrap begin
- bootstrap complete
- coordinator initialization
- Governance loading
- contract registry loading
- diagnostics
- snapshots
- validation
- shutdown
- cleanup inside Studio

Framework cleanup of generated local artifacts is still validated.
