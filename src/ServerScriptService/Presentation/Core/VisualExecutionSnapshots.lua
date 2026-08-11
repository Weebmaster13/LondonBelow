--!strict

local Runtime = require(script.Parent.RuntimeRobloxVisualCompositionExecution)

local Snapshots = {}

function Snapshots.capture()
	return Runtime.getSnapshot()
end

return Snapshots
