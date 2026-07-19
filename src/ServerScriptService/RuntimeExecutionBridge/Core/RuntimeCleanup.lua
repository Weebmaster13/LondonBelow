--!strict

local State = require(script.Parent.State)

local RuntimeCleanup = {}

function RuntimeCleanup.run(): any
	State.markCleanup(true, true)
	return {
		started = true,
		completed = true,
		warnings = {},
	}
end

return RuntimeCleanup
