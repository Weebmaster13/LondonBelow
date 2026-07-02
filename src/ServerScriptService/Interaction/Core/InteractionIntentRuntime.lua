--!strict
-- Future interaction intent records. Intent records do not submit execution.

local Serialization = require(script.Parent.InteractionSerialization)
local Validation = require(script.Parent.InteractionValidation)

local Intent = {}

function Intent.record(state: any, intent: any): (boolean, string?)
	if type(intent) ~= "table" then
		return false, "interaction intent must be a table"
	end
	local safe, reason = Validation.safePayload(intent)
	if not safe then
		return false, reason
	end
	if not Validation.id(intent.intentId) then
		return false, "intentId is required"
	end
	if not Validation.id(intent.interactionId) then
		return false, "interactionId is required"
	end
	if not state.exists(intent.interactionId) then
		return false, "unknown interactionId"
	end
	state.addIntent(Serialization.deepCopy({
		intentId = intent.intentId,
		interactionId = intent.interactionId,
		sourceSystem = intent.sourceSystem,
		reason = intent.reason,
		context = intent.context or {},
		recordedAt = os.clock(),
		wouldSubmitExecution = false,
		wouldCreatePrompt = false,
	}))
	return true, nil
end

return Intent
