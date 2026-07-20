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
		definitionId = schema.definitionId or schema.interactionId,
		targetId = schema.targetId,
		physicalObjectId = schema.physicalObjectId,
		interactionType = schema.interactionType,
		interactionStatus = schema.interactionStatus or "Registered",
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

function Registration.registerTarget(state: any, target: any): (boolean, string?)
	local ok, reason = Validation.target(target)
	if not ok then
		return false, reason
	end
	if state.targetExists(target.targetId) then
		return false, "duplicate targetId"
	end
	state.addTarget({
		targetId = target.targetId,
		ownerSystem = target.ownerSystem,
		targetStatus = target.targetStatus or "Registered",
		adapterKind = target.adapterKind or "SchemaOnly",
		metadata = target.metadata or {},
	})
	return true, nil
end

return Registration
