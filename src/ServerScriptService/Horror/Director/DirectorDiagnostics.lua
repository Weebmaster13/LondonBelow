--!strict
-- Diagnostics aggregation for the Psychological Horror Director.

local DirectorDiagnostics = {}

function DirectorDiagnostics.capture(state: any, dependencies: { [string]: any })
	return {
		state = state,
		profiles = dependencies.PlayerFearProfile.inspect(),
		memory = dependencies.DirectorMemory.inspect(),
		cooldowns = dependencies.ScareCooldowns.inspect(),
		scareCount = #dependencies.ScareRegistry.getAll(),
	}
end

function DirectorDiagnostics.validate(dependencies: { [string]: any }): (boolean, string?)
	local registryOk, registryErr = dependencies.ScareRegistry.validate()

	if not registryOk then
		return false, registryErr
	end

	local profileOk, profileErr = dependencies.PlayerFearProfile.validate()

	if not profileOk then
		return false, profileErr
	end

	return true, nil
end

return DirectorDiagnostics
