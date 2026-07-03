# Runtime Dependency Runtime

Dependency edges are schema relationships, not service resolution.

Dependency records require registered source and target nodes. Self-dependencies reject. Direct required A-to-B and B-to-A cycles reject when represented directly. Optional, soft, diagnostic, snapshot, governance, future-adapter, forbidden, superseded, and historical dependencies remain records only.

Dependency records do not call runtime APIs, initialize systems, shut down systems, or resolve services.
