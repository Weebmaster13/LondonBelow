--!strict
-- Story gate schema registration. Gates are eligibility data, not execution.

local Validation = require(script.Parent.NarrativeValidation)

local StoryGateRuntime = {}

function StoryGateRuntime.register(state: any, gate: any): (boolean, string?)
	local ok, reason = Validation.storyGate(gate)
	if not ok then
		return false, reason
	end
	if state.hasGate(gate.gateId) then
		return false, "duplicate gateId"
	end
	state.addGate({
		gateId = gate.gateId,
		beatId = gate.beatId,
		requirements = gate.requirements or {},
		registeredAt = os.clock(),
	})
	return true, nil
end

return StoryGateRuntime
