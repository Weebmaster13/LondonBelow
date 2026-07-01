--!strict
-- Builds identity-pressure context without owning identity truth.

local IdentityAwareness = {}

function IdentityAwareness.fromObservation(observation: any)
	local metadata = if type(observation) == "table"
			and type(observation.metadata) == "table"
		then observation.metadata
		else {}
	local exposure = if type(metadata.identityExposure) == "number"
		then math.clamp(metadata.identityExposure, 0, 1)
		else 0
	return {
		source = "IdentityAwareness",
		signals = { identity = exposure, memory = exposure * 0.8, journal = exposure * 0.5 },
		identityExposure = exposure,
		targetPlayerId = if type(observation) == "table" then observation.playerId else nil,
		targetZoneId = if type(observation) == "table" then observation.zoneId else nil,
		reason = "identity exposure changed monster attention",
	}
end

return IdentityAwareness
