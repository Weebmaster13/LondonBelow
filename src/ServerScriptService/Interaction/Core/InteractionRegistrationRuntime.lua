--!strict
-- Registers interaction object schemas. This does not execute interactions.

local Validation = require(script.Parent.InteractionValidation)

local Registration = {}

function Registration.register(state: any, schema: any): (boolean, string?)
	local ok, reason = Validation.schema(schema)
	if not ok then
		return false, reason
	end
	if state.exists(schema.interactionId) then
		return false, "duplicate interactionId"
	end
	state.add({
		interactionId = schema.interactionId,
		physicalObjectId = schema.physicalObjectId,
		interactionType = schema.interactionType,
		ownerSystem = schema.ownerSystem,
		eligibility = schema.eligibility or {},
		requiredState = schema.requiredState or {},
		cooldown = schema.cooldown or {},
		lockState = schema.lockState or {},
		metadata = schema.metadata or {},
		context = schema.context or {},
		tags = schema.tags or {},
		registeredAt = os.clock(),
	})
	return true, nil
end

return Registration
