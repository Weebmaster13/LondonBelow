--!strict
-- Emotional beat protection. It can suppress pressure recommendations only.

local Validation = require(script.Parent.NarrativeValidation)

local EmotionalBeatRuntime = {}

function EmotionalBeatRuntime.registerProtection(state: any, beat: any): (boolean, string?)
	local ok, reason = Validation.emotionalBeat(beat)
	if not ok then
		return false, reason
	end
	state.addEmotionalProtection({
		emotionalBeatId = beat.emotionalBeatId,
		beatId = beat.beatId,
		pressureLimit = math.clamp(beat.pressureLimit, 0, 100),
		metadata = beat.metadata or {},
		registeredAt = os.clock(),
	})
	return true, nil
end

function EmotionalBeatRuntime.shouldSuppressPressure(protection: any, pressure: number): boolean
	if type(protection) ~= "table" or type(protection.pressureLimit) ~= "number" then
		return false
	end
	return pressure > protection.pressureLimit
end

return EmotionalBeatRuntime
