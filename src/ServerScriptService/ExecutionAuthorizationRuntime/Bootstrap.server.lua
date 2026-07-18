--!strict

-- Main engine startup owns ExecutionAuthorizationCoordinator registration through
-- Core/Bootstrap.server.lua. This local script intentionally has no runtime
-- side effects so authorization never auto-runs outside governed bootstrap.
