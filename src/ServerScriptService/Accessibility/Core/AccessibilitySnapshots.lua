--!strict
-- Snapshot provider for Accessibility Runtime Foundation.

local Serialization = require(script.Parent.AccessibilitySerialization)
local Types = require(script.Parent.AccessibilityTypes)

local Snapshots = {}

function Snapshots.capture(state: any)
	local inspected = state.inspect()
	local snapshot = Serialization.deepCopy({
		mode = Types.Mode,
		counts = inspected.counts,
		settings = inspected.settings,
		visuals = inspected.visuals,
		audios = inspected.audios,
		inputs = inspected.inputs,
		motions = inspected.motions,
		readabilities = inspected.readabilities,
		contentWarnings = inspected.contentWarnings,
		recentValidationFailures = inspected.validationFailures,
	})
	state.recordSnapshot(snapshot)
	return snapshot
end

return Snapshots
