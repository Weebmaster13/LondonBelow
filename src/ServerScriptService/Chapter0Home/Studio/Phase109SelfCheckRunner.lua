--!strict
--[[
	Manual Roblox Studio self-check entry point for Phase 109.

	This module does not run automatically. Use the Studio command bar with the
	explicit Workspace flag documented in SELF_CHECK_RUNTIME.md.
]]

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local SharedRunner = require(script.Parent.Chapter0HomeStudioSelfCheckRunner)

local Runner = {}

local FLAG_NAME = "LondonPhase109RunSelfChecks"
local SUITE_NAME = "Phase 109 Studio Runtime Self-Checks"

function Runner.run()
	if not RunService:IsStudio() then
		error("Phase 109 self-check runner is Studio-only.", 0)
	end

	if Workspace:GetAttribute(FLAG_NAME) ~= true then
		error(
			"Phase 109 self-check runner requires Workspace attribute " .. FLAG_NAME .. " = true.",
			0
		)
	end

	return SharedRunner.run(SUITE_NAME)
end

return Runner
