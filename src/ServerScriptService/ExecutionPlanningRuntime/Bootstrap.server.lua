--!strict

-- Main engine startup owns ExecutionPlanningCoordinator registration through
-- Core/Bootstrap.server.lua. This script intentionally has no runtime side
-- effects so the subsystem never auto-executes outside the governed bootstrap.
