--!strict

local State = require(script.Parent.State)

local RuntimeDiagnostics = {}

function RuntimeDiagnostics.capture(context: any): { any }
	local diagnostics = {
		{
			level = "Info",
			code = "BridgeActive",
			message = "Runtime Execution Bridge captured Studio server observations.",
		},
		{
			level = "Warning",
			code = "FilesystemWriterUnavailable",
			message = "Roblox server runtime cannot write the local expected runtime-result.json path without a supported export channel.",
		},
		{
			level = "Info",
			code = "CoordinatorObservation",
			message = "Observed coordinator ModuleScript count: "
				.. tostring(context.coordinatorCount),
		},
	}
	for _, diagnostic in ipairs(diagnostics) do
		State.recordDiagnostic(diagnostic)
	end
	return diagnostics
end

return RuntimeDiagnostics
