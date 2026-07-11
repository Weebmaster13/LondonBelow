# Asset Execution Authorization Self-Checks

Executable self-checks verify provider consistency, snapshot kind consistency, Bootstrap dependency ordering, schema terminology, exact field validation, enum validation, duplicate id rejection, reference validation, failed validation no mutation, snapshot isolation, diagnostics isolation, lowerCamelCase posture keys, shutdown cleanup, bounded payload validation, and banned runtime-surface absence.

The self-checks intentionally treat authorization as metadata only. Passing self-checks does not create execution permission, approval authority, rejection authority, routing, dispatch, scheduling, orchestration, asset loading, gameplay execution, Presentation execution, Save execution, or Chapter content.
