--!strict
-- Diagnostics for World Runtime Foundation.

local Serialization = require(script.Parent.WorldSerialization)
local Types = require(script.Parent.WorldTypes)

local Diagnostics = {}

function Diagnostics.capture(lifecycle: any, dependencies: any)
	local state = dependencies.State.inspect()
	local validationOk, validationReason = dependencies.Validation.validate()
	local health = "Healthy"
	if not validationOk then
		health = "Unhealthy"
	elseif state.counts.validationFailures > 0 then
		health = "Warning"
	end

	return Serialization.deepCopy({
		health = health,
		validationOk = validationOk,
		validationReason = validationReason,
		lifecycleState = lifecycle.started and "Started"
			or (lifecycle.initialized and "Initialized" or "Stopped"),
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		lastSelfChecks = lifecycle.lastSelfChecks,
		counts = state.counts,
		limits = Types.Limits,
		mode = Types.Mode,
		serializationPosture = {
			rejectsInstances = true,
			rejectsUnsafeRuntimeValues = true,
			rejectsCycles = true,
			rejectsOversizedPayloads = true,
			exportsDeepCopies = true,
		},
		snapshotIsolationProof = {
			snapshotsAreDeepCopies = true,
			diagnosticsAreDeepCopies = true,
			unsafeRuntimeValuesAreSanitized = true,
		},
		perCategoryLimitState = {
			districts = state.counts.districts .. "/" .. Types.Limits.MaxDistricts,
			regions = state.counts.regions .. "/" .. Types.Limits.MaxRegions,
			buildings = state.counts.buildings .. "/" .. Types.Limits.MaxBuildings,
			floors = state.counts.floors .. "/" .. Types.Limits.MaxFloors,
			rooms = state.counts.rooms .. "/" .. Types.Limits.MaxRooms,
			zones = state.counts.zones .. "/" .. Types.Limits.MaxZones,
			connections = state.counts.connections .. "/" .. Types.Limits.MaxConnections,
			streamingRegions = state.counts.streamingRegions
				.. "/"
				.. Types.Limits.MaxStreamingRegions,
			classifications = state.counts.classifications
				.. "/"
				.. Types.Limits.MaxClassifications,
			tags = state.counts.tags .. "/" .. Types.Limits.MaxTags,
		},
		noExecutionPosture = {
			noWorkspaceMutation = true,
			noTerrainGeneration = true,
			noMapGeneration = true,
			noStreamingExecution = true,
			noRoomLoading = true,
			noTeleporting = true,
			noMovement = true,
			noPathfinding = true,
			noPhysics = true,
			noRemotes = true,
			noClientAuthority = true,
			noChapterContent = true,
		},
		recentValidationFailures = state.validationFailures,
	})
end

function Diagnostics.validate(dependencies: any): (boolean, string?)
	local ok, reason = dependencies.Validation.validate()
	if not ok then
		return false, reason
	end
	local state = dependencies.State.inspect()
	if state.counts.districts > Types.Limits.MaxDistricts then
		return false, "district count exceeds limit"
	end
	if state.counts.rooms > Types.Limits.MaxRooms then
		return false, "room count exceeds limit"
	end
	if state.counts.zones > Types.Limits.MaxZones then
		return false, "zone count exceeds limit"
	end
	return true, nil
end

return Diagnostics
