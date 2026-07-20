# Session Model

Each accepted request creates a bounded session with session id, request id, interaction id, target id, player key, status, timing, authorization, plan, and result.

Session history is bounded by `Types.Limits.MaxSessions`.
