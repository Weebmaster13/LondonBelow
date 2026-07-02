--!strict
-- Interaction cooldown schema records. These are data only.

local Validation = require(script.Parent.InteractionValidation)

local Cooldown = {}

function Cooldown.record(state: any, interactionId: string, cooldown: any): (boolean, string?)
	if not Validation.id(interactionId) then
		return false, "interactionId is required"
	end
	if not state.exists(interactionId) then
		return false, "unknown interactionId"
	end
	local ok, reason = Validation.cooldown(cooldown)
	if not ok then
		return false, reason
	end
	state.setCooldown(interactionId, cooldown or {})
	return true, nil
end

return Cooldown
