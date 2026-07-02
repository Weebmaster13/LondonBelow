--!strict
-- Narrative beat schema registration. Beats are state schemas, not story prose.

local Validation = require(script.Parent.NarrativeValidation)

local BeatRuntime = {}

function BeatRuntime.register(state: any, beat: any): (boolean, string?)
	local ok, reason = Validation.beat(beat)
	if not ok then
		return false, reason
	end
	if state.hasBeat(beat.beatId) then
		return false, "duplicate beatId"
	end
	state.addBeat({
		beatId = beat.beatId,
		schemaKind = beat.schemaKind or "NarrativeBeatSchema",
		journalEntryId = beat.journalEntryId,
		memoryFragmentId = beat.memoryFragmentId,
		identityRequirement = beat.identityRequirement,
		metadata = beat.metadata or {},
		registeredAt = os.clock(),
	})
	return true, nil
end

return BeatRuntime
