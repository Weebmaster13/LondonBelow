--!strict

local DirectorConfig = require(script.Parent.DirectorConfig)

local DirectorDiagnostics = {}

function DirectorDiagnostics.capture(state: any, dependencies: { [string]: any })
	local directorsByName = dependencies.directorsByName
	local missing = {}
	local capabilityMap = dependencies.DirectorCapabilities.inspect()
	local health = dependencies.DirectorHealth.summarize(directorsByName)

	for _, directorName in ipairs(DirectorConfig.RequiredDirectors) do
		if directorsByName[directorName] == nil then
			table.insert(missing, directorName)
		end
	end

	return {
		state = state,
		registeredDirectors = table.clone(dependencies.registrationOrder),
		missingRequiredDirectors = missing,
		directorHealth = health,
		pendingRequestCount = dependencies.pendingRequestCount(),
		recentApprovals = dependencies.recentApprovals(),
		metrics = dependencies.metrics(),
		traces = dependencies.DirectorDecisionTrace.inspect(),
		conflicts = dependencies.DirectorConflictResolver.inspect(),
		capabilityMap = capabilityMap,
		recentFailures = dependencies.recentFailures(),
	}
end

function DirectorDiagnostics.validate(dependencies: { [string]: any }): (boolean, string?)
	for _, directorName in ipairs(DirectorConfig.RequiredDirectors) do
		if dependencies.directorsByName[directorName] == nil then
			return false, "Missing required Director: " .. directorName
		end
	end

	return true, nil
end

return DirectorDiagnostics
