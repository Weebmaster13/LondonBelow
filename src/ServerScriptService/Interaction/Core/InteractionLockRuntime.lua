--!strict
-- Interaction lock schema records. These are not physics locks.

local Validation = require(script.Parent.InteractionValidation)

local LockRuntime = {}

function LockRuntime.record(state: any, interactionId: string, lockState: any): (boolean, string?)
	if not Validation.id(interactionId) then
		return false, "interactionId is required"
	end
	if not state.exists(interactionId) then
		return false, "unknown interactionId"
	end
	local ok, reason = Validation.lock(lockState)
	if not ok then
		return false, reason
	end
	state.setLock(interactionId, lockState or {})
	return true, nil
end

return LockRuntime
