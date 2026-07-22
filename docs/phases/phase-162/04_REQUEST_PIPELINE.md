# Request Pipeline

Persistence requests contain `requestId`, `operation`, `provider`, `saveId`, `payload`, and `timestamp`.

Supported operations are `Load`, `Save`, `Delete`, `Exists`, and `List`.

The pipeline validates requests before provider resolution, records bounded request evidence, rejects missing providers, rejects unsupported operations, and never mutates gameplay.
