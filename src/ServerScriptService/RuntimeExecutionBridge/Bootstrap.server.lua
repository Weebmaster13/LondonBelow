--!strict

local RunService = game:GetService("RunService")

local BridgeCoordinator = require(script.Parent.Core.BridgeCoordinator)

local ENABLE_ATTRIBUTE = "LondonRuntimeExecutionBridgeEnabled"

if RunService:IsStudio() and game:GetAttribute(ENABLE_ATTRIBUTE) == true then
	local initialized = BridgeCoordinator.initialize()
	if not initialized.ok then
		error(
			"Runtime Execution Bridge initialization failed: " .. tostring(initialized.message),
			0
		)
	end

	local started = BridgeCoordinator.start()
	if not started.ok then
		warn("Runtime Execution Bridge blocked: " .. tostring(started.message))
	end
end
