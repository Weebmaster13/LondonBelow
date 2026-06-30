--!strict
--[[
	Diagnostics aggregation for Observation Engine.

	Owns read-only inspection and validation across Observation Engine modules.

	Does not own runtime behavior, observation mutation, or final reporting UI.
]]

local ObservationDiagnostics = {}

function ObservationDiagnostics.capture(state: any, dependencies: { [string]: any })
	return {
		state = state,
		registryCount = #dependencies.ObservationRegistry.ids(),
		context = dependencies.ObservationContext.inspect(),
		memory = dependencies.ObservationMemory.inspect(),
		timeline = dependencies.ObservationTimeline.inspect(),
		aggregates = dependencies.ObservationAggregator.snapshot(),
		patterns = dependencies.ObservationPatternRecognizer.inspect(),
		profiler = dependencies.ObservationProfiler.inspect(),
	}
end

function ObservationDiagnostics.validate(dependencies: { [string]: any }): (boolean, string?)
	local modules = {
		"ObservationConfig",
		"ObservationRegistry",
		"ObservationContext",
		"ObservationMemory",
		"ObservationTimeline",
		"ObservationAggregator",
		"ObservationPatternRecognizer",
		"ObservationProfiler",
	}

	for _, moduleName in ipairs(modules) do
		local module = dependencies[moduleName]

		if module == nil or type(module.validate) ~= "function" then
			return false, "Observation diagnostics missing validate hook: " .. moduleName
		end

		local ok, err = module.validate()

		if not ok then
			return false, err
		end
	end

	return true, nil
end

return ObservationDiagnostics
