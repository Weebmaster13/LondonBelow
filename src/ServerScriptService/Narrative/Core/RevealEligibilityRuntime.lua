--!strict
-- Reveal eligibility grants. This records permission, not the reveal itself.

local Validation = require(script.Parent.NarrativeValidation)

local RevealEligibilityRuntime = {}

function RevealEligibilityRuntime.grant(state: any, reveal: any): (boolean, string?)
	local ok, reason = Validation.revealEligibility(reveal)
	if not ok then
		return false, reason
	end
	state.addReveal({
		revealId = reveal.revealId,
		beatId = reveal.beatId,
		journalEntryId = reveal.journalEntryId,
		memoryFragmentId = reveal.memoryFragmentId,
		identityDelta = reveal.identityDelta,
		context = reveal.context or {},
		eligible = true,
		grantedAt = os.clock(),
	})
	return true, nil
end

return RevealEligibilityRuntime
