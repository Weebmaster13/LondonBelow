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

local function buildPolicySafetySummary(registrySnapshot: any, validationOk: boolean)
	local unsafeMonsterRevealZones = {}
	local unsafeChaseZones = {}
	local unsafeBlackoutZones = {}
	local unsafePuzzleInterruptionZones = {}

	for zoneId, profile in pairs(registrySnapshot.zoneProfiles or {}) do
		if profile.monsterPolicy ~= nil and profile.monsterPolicy.allowsMainMonsterReveal then
			table.insert(unsafeMonsterRevealZones, zoneId)
		end

		if profile.monsterPolicy ~= nil and profile.monsterPolicy.allowsChaseStart then
			table.insert(unsafeChaseZones, zoneId)
		end

		if profile.lightingPolicy ~= nil and profile.lightingPolicy.allowsBlackout then
			table.insert(unsafeBlackoutZones, zoneId)
		end

		if
			profile.puzzleProtection ~= nil and profile.puzzleProtection.allowsMajorInterruptions
		then
			table.insert(unsafePuzzleInterruptionZones, zoneId)
		end
	end

	return {
		validationOk = validationOk,
		unknownZonesConservative = true,
		defaultMonsterRevealAllowed = false,
		defaultChaseStartAllowed = false,
		defaultBlackoutAllowed = false,
		defaultMajorPuzzleInterruptionAllowed = false,
		zonesAllowingMonsterReveal = unsafeMonsterRevealZones,
		zonesAllowingChaseStart = unsafeChaseZones,
		zonesAllowingBlackout = unsafeBlackoutZones,
		zonesAllowingMajorPuzzleInterruptions = unsafePuzzleInterruptionZones,
	}
end

function WorldDiagnostics.capture()
	local registrySnapshot = Registry.inspect()
	local contextSnapshot = ZoneContext.inspect()
	local validationOk, validationError = Registry.validate()

	return {
		registry = registrySnapshot,
		context = contextSnapshot,
		profileCounts = {
			atmosphere = registrySnapshot.atmosphereProfileCount,
			room = registrySnapshot.roomProfileCount,
			zone = registrySnapshot.zoneProfileCount,
		},
		recentContextCount = contextSnapshot.recentContextCount,
		validation = {
			ok = validationOk,
			error = validationError,
		},
		policySafety = buildPolicySafetySummary(registrySnapshot, validationOk),
	}
end

function WorldDiagnostics.validate(): (boolean, string?)
	return Registry.validate()
end

return WorldDiagnostics
