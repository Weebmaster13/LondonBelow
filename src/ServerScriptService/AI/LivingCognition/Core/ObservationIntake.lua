--!strict
-- Normalizes trusted observations without interpreting meaning.

local Serialization = require(script.Parent.LivingCognitionSerialization)
local Validation = require(script.Parent.LivingCognitionValidation)

local ObservationIntake = {}

function ObservationIntake.normalize(raw: any)
	local receivedAt = os.clock()
	local observation = {
		observationId = if type(raw) == "table" then raw.observationId else nil,
		entityId = if type(raw) == "table" then raw.entityId else nil,
		sourceSystem = if type(raw) == "table" then raw.sourceSystem else nil,
		observedAt = if type(raw) == "table" and raw.observedAt ~= nil
			then raw.observedAt
			else receivedAt,
		receivedAt = receivedAt,
		confidence = if type(raw) == "table" and raw.confidence ~= nil then raw.confidence else 0.5,
		provenance = if type(raw) == "table" and type(raw.provenance) == "string"
			then raw.provenance
			else "Unknown",
		payload = if type(raw) == "table" and raw.payload ~= nil
			then Serialization.deepCopy(raw.payload)
			else {},
		traceId = if type(raw) == "table" and type(raw.traceId) == "string"
			then raw.traceId
			else "trace:" .. tostring(math.floor(receivedAt * 1000)),
	}
	local ok, reason = Validation.observation(observation)
	if not ok then
		return nil, reason
	end
	return observation, nil
end

return ObservationIntake
