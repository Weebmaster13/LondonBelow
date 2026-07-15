--!strict
--[[
	Manual Roblox Studio self-check entry point for Phase 109.

	This module does not run automatically. Use the Studio command bar with the
	explicit Workspace flag documented in SELF_CHECK_RUNTIME.md.
]]

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Chapter0HomeCoordinator = require(script.Parent.Parent.Core.Chapter0HomeCoordinator)
local InteractionCoordinator = require(ServerScriptService.Interaction.Core.InteractionCoordinator)
local ObservationService = require(ServerScriptService.Horror.Observation.ObservationService)
local PlayerExperienceService = require(ServerScriptService.Gameplay.PlayerExperienceService)

local Runner = {}

local FLAG_NAME = "LondonPhase109RunSelfChecks"

type FlatResult = {
	name: string,
	ok: boolean,
	message: string?,
}

local function messageFrom(result: any): string?
	if type(result) ~= "table" then
		return nil
	end

	return result.detail or result.reason or result.error or result.message
end

local function hasOk(value: any): boolean
	return type(value) == "table" and type(value.ok) == "boolean"
end

local function flatten(name: string, value: any, output: { FlatResult })
	if type(value) ~= "table" then
		table.insert(output, {
			name = name,
			ok = value == true,
			message = if value == true then nil else "non-table self-check result",
		})
		return
	end

	if type(value.results) == "table" then
		for _, child in ipairs(value.results) do
			local childName = if type(child) == "table" and type(child.name) == "string"
				then child.name
				else "unnamed check"
			table.insert(output, {
				name = name .. " :: " .. childName,
				ok = type(child) == "table" and child.ok == true,
				message = messageFrom(child),
			})
		end
		return
	end

	if hasOk(value) then
		table.insert(output, {
			name = name,
			ok = value.ok == true,
			message = messageFrom(value),
		})
	end

	for key, child in pairs(value) do
		if type(child) == "table" and key ~= "results" then
			flatten(name .. "." .. tostring(key), child, output)
		end
	end
end

local function runSuite(name: string, callback: () -> any, output: { FlatResult })
	local ok, result = pcall(callback)

	if not ok then
		table.insert(output, {
			name = name,
			ok = false,
			message = tostring(result),
		})
		return
	end

	flatten(name, result, output)
end

local function summarize(results: { FlatResult })
	local failed = 0

	for _, result in ipairs(results) do
		if not result.ok then
			failed += 1
		end
	end

	return {
		total = #results,
		passed = #results - failed,
		failed = failed,
	}
end

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

	local results: { FlatResult } = {}

	runSuite("Phase109.Chapter0Home", function()
		return Chapter0HomeCoordinator.runSelfChecks()
	end, results)

	runSuite("Upstream.PlayerExperience", function()
		return PlayerExperienceService.runSelfChecks()
	end, results)

	runSuite("Upstream.InteractionRuntime", function()
		return InteractionCoordinator.runSelfChecks()
	end, results)

	runSuite("Upstream.ObservationEngine", function()
		return ObservationService.runSelfChecks()
	end, results)

	local summary = summarize(results)

	print("Suite: Phase 109 Studio Runtime Self-Checks")
	print("Total checks: " .. tostring(summary.total))
	print("Passed checks: " .. tostring(summary.passed))
	print("Failed checks: " .. tostring(summary.failed))

	for _, result in ipairs(results) do
		if not result.ok then
			print(
				"FAIL: " .. result.name .. " - " .. tostring(result.message or "no failure message")
			)
		end
	end

	if summary.failed > 0 then
		print("Final: FAIL")
		error("Phase 109 Studio Runtime Self-Checks failed.", 0)
	end

	print("Final: PASS")
	return {
		suite = "Phase 109 Studio Runtime Self-Checks",
		total = summary.total,
		passed = summary.passed,
		failed = summary.failed,
		results = results,
	}
end

return Runner
