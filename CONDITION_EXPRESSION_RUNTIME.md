# Condition Expression Runtime

Condition expressions describe future condition structure. They reference a condition id, an operator id, and optional operand ids.

Expressions are descriptions, not computations. They do not compare values, read runtime state, branch gameplay, evaluate booleans, call functions, dispatch events, or produce truth.

Expression validation proves referenced conditions, operators, and operands exist before registration. Operand lists are bounded to prevent schema growth from becoming an execution surface.

## Production Hardening

Expressions reject unsupported schema types, invalid condition references, invalid operator references, invalid operand references, oversized operand lists, unsafe payloads, expression evaluation markers, boolean execution markers, scripting markers, callbacks, executable functions, runtime objects, and live value handles.
