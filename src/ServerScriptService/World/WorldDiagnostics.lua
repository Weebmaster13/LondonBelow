--!strict
--[[
	Diagnostics helpers for passive World Intelligence contracts.

	This module exposes state for health checks and snapshots without registering
	a lifecycle service. Future systems may include these diagnostics in their
	own reports when they consume world context.
]]

local Registry = require(script.Parent.WorldProfileRegistry)
local ZoneContext = require(script.Parent.WorldZoneContext)

local WorldDiagnostics = {}

function WorldDiagnostics.capture()
	return {
		registry = Registry.inspect(),
		context = ZoneContext.inspect(),
	}
end

function WorldDiagnostics.validate(): (boolean, string?)
	return Registry.validate()
end

return WorldDiagnostics
