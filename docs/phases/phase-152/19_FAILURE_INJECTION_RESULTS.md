# Failure Injection Results

Self-checks cover:

- unavailable backend;
- malformed backend registration;
- mismatched session;
- mismatched commit;
- unsupported schema version;
- attempted certification mutation;
- path traversal;
- missing evidence;
- timeout classification;
- interrupted/missing session recovery;
- bridge malformed-success prevention;
- MCP unsupported-state preservation.

No false runtime success is reported.
