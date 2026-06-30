--!strict
--[[
	Diagnostics aggregation for the Psychological Horror Director.

	Owns read-only snapshots of Director state for Diagnostics and
	SnapshotManager.

	Does not own runtime behavior, scare selection, profile mutation, or logging
	policy.

	Expected data: dependency table containing modules with inspect/validate
	methods. This loose dependency shape keeps diagnostics from creating circular
	requires.

	Returns: serializable tables safe for server debugging.
]]

local DirectorDiagnostics = {}

function DirectorDiagnostics.capture(state: any, dependencies: { [string]: any })
	-- Capture is intentionally broad and read-only. If this becomes too large,
	-- trim diagnostic shape here instead of weakening module internals.
	return {
		state = state,
		profiles = dependencies.PlayerFearProfile.inspect(),
		memory = dependencies.DirectorMemory.inspect(),
		cooldowns = dependencies.ScareCooldowns.inspect(),
		scareCount = #dependencies.ScareRegistry.getAll(),
	}
end

function DirectorDiagnostics.validate(dependencies: { [string]: any }): (boolean, string?)
	local configOk, configErr = dependencies.HorrorDirectorConfig.validate()

	if not configOk then
		return false, configErr
	end

	local registryOk, registryErr = dependencies.ScareRegistry.validate()

	if not registryOk then
		return false, registryErr
	end

	local profileOk, profileErr = dependencies.PlayerFearProfile.validate()

	if not profileOk then
		return false, profileErr
	end

	local memoryOk, memoryErr = dependencies.DirectorMemory.validate()

	if not memoryOk then
		return false, memoryErr
	end

	local cooldownOk, cooldownErr = dependencies.ScareCooldowns.validate()

	if not cooldownOk then
		return false, cooldownErr
	end

	return true, nil
end

return DirectorDiagnostics
