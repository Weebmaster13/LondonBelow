--!strict
--[[
	Manual Roblox Studio runtime-certification entry point for Phase 110.

	This module does not run automatically. Use the explicit Workspace flag
	documented in SELF_CHECK_RUNTIME.md.
]]

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local SharedRunner = require(script.Parent.Chapter0HomeStudioSelfCheckRunner)

local Runner = {}

local FLAG_NAME = "LondonPhase110RunSelfChecks"
local SUITE_NAME = "Phase 110 Studio Runtime Certification"

function Runner.run()
	if not RunService:IsStudio() then
		error("Phase 110 certification runner is Studio-only.", 0)
	end

	if Workspace:GetAttribute(FLAG_NAME) ~= true then
		error(
			"Phase 110 certification runner requires Workspace attribute "
				.. FLAG_NAME
				.. " = true.",
			0
		)
	end

	return SharedRunner.run(SUITE_NAME)
end

return Runner
