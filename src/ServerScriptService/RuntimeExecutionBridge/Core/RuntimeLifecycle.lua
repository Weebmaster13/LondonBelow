--!strict

local State = require(script.Parent.State)
local Types = require(script.Parent.Types)

local RuntimeLifecycle = {}

function RuntimeLifecycle.startBridge()
	State.setLifecycle(Types.LifecycleState.BridgeStarted)
	State.recordEvent(
		"Bridge Started",
		"VERIFIED",
		"Runtime Execution Bridge started in Studio-gated mode."
	)
end

function RuntimeLifecycle.startCapture()
	State.setLifecycle(Types.LifecycleState.Capturing)
	State.recordEvent("Bootstrap Started", "OBSERVED", "Bridge capture began.")
end

function RuntimeLifecycle.completeCapture()
	State.recordEvent(
		"Bootstrap Finished",
		"OBSERVED",
		"Bridge capture completed its observation pass."
	)
end

function RuntimeLifecycle.cleanup()
	State.recordEvent("Cleanup Started", "VERIFIED", "Bridge cleanup began.")
	State.markCleanup(true, true)
	State.recordEvent("Shutdown", "VERIFIED", "Bridge shutdown and cleanup completed.")
end

return RuntimeLifecycle
