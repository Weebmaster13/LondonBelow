--!strict
--[[
	Diagnostics reports London Engine health.

	It samples memory, player counts, startup duration, loaded services, warning
	and error counters, and extension hooks for future FPS/network metrics.
]]

local Players = game:GetService("Players")

local Logger = require(script.Parent.Logger)

local Diagnostics = {}

export type HealthReport = {
	healthy: boolean,
	startupDuration: number,
	memoryKb: number,
	playerCount: number,
	loadedServices: { string },
	warnings: number,
	errors: number,
	custom: { [string]: any },
}

local log = Logger.scope("Diagnostics")
local warnings = 0
local errors = 0
local customSamplers: { [string]: () -> any } = {}
local serviceProvider: (() -> { string })? = nil
local startupDurationProvider: (() -> number)? = nil

function Diagnostics.configure(
	getServices: (() -> { string })?,
	getStartupDuration: (() -> number)?
)
	serviceProvider = getServices
	startupDurationProvider = getStartupDuration
end

function Diagnostics.registerSampler(name: string, callback: () -> any)
	assert(type(name) == "string" and name ~= "", "name must be a non-empty string")
	assert(type(callback) == "function", "callback must be a function")

	customSamplers[name] = callback
end

function Diagnostics.incrementWarning()
	warnings += 1
end

function Diagnostics.incrementError()
	errors += 1
end

function Diagnostics.capture(): HealthReport
	local custom = {}

	for name, sampler in pairs(customSamplers) do
		local ok, result = pcall(sampler)

		if ok then
			custom[name] = result
		else
			errors += 1
			custom[name] = "Sampler failed: " .. tostring(result)
		end
	end

	local loadedServices = {}

	if serviceProvider ~= nil then
		local ok, result = pcall(serviceProvider)

		if ok then
			loadedServices = result
		else
			errors += 1
			log.withContext("ERROR", "Service provider failed", {
				error = tostring(result),
			})
		end
	end

	return {
		healthy = errors == 0,
		startupDuration = if startupDurationProvider ~= nil then startupDurationProvider() else 0,
		memoryKb = collectgarbage("count"),
		playerCount = #Players:GetPlayers(),
		loadedServices = loadedServices,
		warnings = warnings,
		errors = errors,
		custom = custom,
	}
end

function Diagnostics.printSummary()
	local report = Diagnostics.capture()

	log.withContext(if report.healthy then "SUCCESS" else "WARN", "Diagnostics summary", {
		startupMs = math.floor(report.startupDuration * 1000),
		memoryKb = math.floor(report.memoryKb),
		playerCount = report.playerCount,
		loadedServices = #report.loadedServices,
		warnings = report.warnings,
		errors = report.errors,
	})

	return report
end

function Diagnostics.validate(): (boolean, string?)
	for name, sampler in pairs(customSamplers) do
		if type(name) ~= "string" or type(sampler) ~= "function" then
			return false, "Invalid diagnostics sampler"
		end
	end

	return true, nil
end

return Diagnostics
