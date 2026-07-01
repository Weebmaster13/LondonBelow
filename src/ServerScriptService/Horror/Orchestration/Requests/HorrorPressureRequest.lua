--!strict
-- Normalizes raw pressure input into a server-owned request.

local Config = require(script.Parent.Parent.Core.HorrorOrchestrationConfig)

local HorrorPressureRequest = {}

function HorrorPressureRequest.create(raw: any)
	local createdAt = if type(raw) == "table" and type(raw.createdAt) == "number"
		then raw.createdAt
		else os.clock()
	return {
		requestId = if type(raw) == "table" then raw.requestId else nil,
		sourceSystem = if type(raw) == "table" then raw.sourceSystem else nil,
		requestKind = if type(raw) == "table" then raw.requestKind else nil,
		priority = if type(raw) == "table" and type(raw.priority) == "number"
			then math.clamp(raw.priority, 0, 100)
			else 0,
		pressure = if type(raw) == "table" and type(raw.pressure) == "number"
			then math.clamp(raw.pressure, 0, 100)
			else 0,
		createdAt = createdAt,
		expiresAt = if type(raw) == "table" and type(raw.expiresAt) == "number"
			then raw.expiresAt
			else createdAt + Config.DefaultRequestTtlSeconds,
		playerUserId = if type(raw) == "table" then raw.playerUserId else nil,
		partyId = if type(raw) == "table" then raw.partyId else nil,
		zoneId = if type(raw) == "table" then raw.zoneId else nil,
		zoneKind = if type(raw) == "table" then raw.zoneKind else nil,
		meaning = if type(raw) == "table" then raw.meaning else nil,
		metadata = if type(raw) == "table" and type(raw.metadata) == "table"
			then table.clone(raw.metadata)
			else {},
		tags = if type(raw) == "table" and type(raw.tags) == "table"
			then table.clone(raw.tags)
			else {},
	}
end

return HorrorPressureRequest
