--!strict
--[[
	Studio-only Chapter 0 Home runtime certification runner.

	This module is a shared implementation for phase-specific manual entry points.
	It never runs automatically; wrapper modules must enforce Studio and explicit
	Workspace flag gates before calling run().
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Chapter0HomeCoordinator = require(script.Parent.Parent.Core.Chapter0HomeCoordinator)
local RemoteManager = require(ServerScriptService.Core.RemoteManager)
local InteractionCoordinator = require(ServerScriptService.Interaction.Core.InteractionCoordinator)
local ObservationService = require(ServerScriptService.Horror.Observation.ObservationService)
local PlayerExperienceService = require(ServerScriptService.Gameplay.PlayerExperienceService)
local RemoteNames = require(ReplicatedStorage.Shared.PlayerExperienceRemoteNames)
local CertificationContract = require(script.Parent.Phase118CertificationContract)

local Runner = {}

type FlatResult = {
	name: string,
	ok: boolean,
	message: string?,
	category: string,
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

local function remoteInstanceName(name: string): string
	return string.format("%s_v%d", name, RemoteNames.Version)
end

local function countChildrenNamed(parent: Instance, childName: string): number
	local count = 0

	for _, child in ipairs(parent:GetChildren()) do
		if child.Name == childName then
			count += 1
		end
	end

	return count
end

local function flatten(name: string, value: any, output: { FlatResult })
	if type(value) ~= "table" then
		table.insert(output, {
			name = name,
			ok = value == true,
			message = if value == true then nil else "non-table self-check result",
			category = "assertion",
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
				category = "assertion",
			})
		end
		return
	end

	if hasOk(value) then
		table.insert(output, {
			name = name,
			ok = value.ok == true,
			message = messageFrom(value),
			category = "assertion",
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
			category = "setup",
		})
		return
	end

	flatten(name, result, output)
end

local function addAssertion(results: { FlatResult }, name: string, ok: boolean, message: string?)
	table.insert(results, {
		name = name,
		ok = ok,
		message = message,
		category = "assertion",
	})
end

local function forEachExpectedRemote(callback: (string) -> ())
	for _, name in pairs(RemoteNames.ClientToServer) do
		callback(name)
	end

	for _, name in pairs(RemoteNames.ServerToClient) do
		callback(name)
	end
end

local function runRemoteContractChecks(results: { FlatResult })
	local root = ReplicatedStorage:FindFirstChild("Remotes")
	addAssertion(
		results,
		"RemoteContract.rootExists",
		root ~= nil and root:IsA("Folder"),
		"expected ReplicatedStorage.Remotes Folder"
	)

	if root == nil then
		return
	end

	local namespace = root:FindFirstChild(RemoteNames.Namespace)
	addAssertion(
		results,
		"RemoteContract.namespaceExists",
		namespace ~= nil and namespace:IsA("Folder"),
		"expected ReplicatedStorage.Remotes." .. RemoteNames.Namespace .. " Folder"
	)

	if namespace == nil then
		return
	end

	forEachExpectedRemote(function(name)
		local instanceName = remoteInstanceName(name)
		local remote = namespace:FindFirstChild(instanceName)

		addAssertion(
			results,
			"RemoteContract.exists." .. instanceName,
			remote ~= nil,
			"expected remote " .. instanceName
		)
		addAssertion(
			results,
			"RemoteContract.remoteEvent." .. instanceName,
			remote ~= nil and remote:IsA("RemoteEvent"),
			"expected RemoteEvent " .. instanceName
		)
		addAssertion(
			results,
			"RemoteContract.noDuplicate." .. instanceName,
			countChildrenNamed(namespace, instanceName) == 1,
			"expected exactly one child named " .. instanceName
		)
	end)

	local requestInteraction = RemoteManager.get(
		RemoteNames.Namespace,
		RemoteNames.ClientToServer.RequestInteraction,
		RemoteNames.Version
	)
	local secondRequestInteraction = RemoteManager.get(
		RemoteNames.Namespace,
		RemoteNames.ClientToServer.RequestInteraction,
		RemoteNames.Version
	)
	addAssertion(
		results,
		"RemoteContract.remoteManagerAdoptsSourceRemote",
		requestInteraction
			== namespace:FindFirstChild(
				remoteInstanceName(RemoteNames.ClientToServer.RequestInteraction)
			),
		"expected RemoteManager to adopt source-declared RequestInteraction_v1"
	)
	addAssertion(
		results,
		"RemoteContract.remoteManagerGetIdempotent",
		requestInteraction == secondRequestInteraction,
		"expected repeated RemoteManager.get calls to reuse the same instance"
	)
	addAssertion(
		results,
		"RemoteContract.remoteManagerNoDuplicateCreation",
		countChildrenNamed(
			namespace,
			remoteInstanceName(RemoteNames.ClientToServer.RequestInteraction)
		) == 1,
		"expected RemoteManager not to create duplicate RequestInteraction_v1"
	)
end

local function summarize(results: { FlatResult })
	local failed = 0
	local setupFailures = 0
	local assertionFailures = 0

	for _, result in ipairs(results) do
		if not result.ok then
			failed += 1

			if result.category == "setup" then
				setupFailures += 1
			else
				assertionFailures += 1
			end
		end
	end

	return {
		total = #results,
		passed = #results - failed,
		failed = failed,
		setupFailures = setupFailures,
		assertionFailures = assertionFailures,
	}
end

local function runInternal(suiteName: string, shouldError: boolean)
	local results: { FlatResult } = {}
	local cleanupErrors = {}

	local function cleanup()
		local ok, err = pcall(function()
			Chapter0HomeCoordinator.shutdown()
		end)

		if not ok then
			table.insert(cleanupErrors, tostring(err))
		end
	end

	cleanup()

	runSuite("Chapter0Home", function()
		return Chapter0HomeCoordinator.runSelfChecks()
	end, results)

	runSuite("Chapter0Home.CertificationContract", function()
		return CertificationContract.runSelfChecks()
	end, results)

	runSuite("Upstream.PlayerExperience", function()
		PlayerExperienceService.initialize()
		return PlayerExperienceService.runSelfChecks()
	end, results)

	runSuite("Upstream.InteractionRuntime", function()
		return InteractionCoordinator.runSelfChecks()
	end, results)

	runSuite("Upstream.ObservationEngine", function()
		return ObservationService.runSelfChecks()
	end, results)

	runSuite("RemoteContract.PlayerExperience", function()
		runRemoteContractChecks(results)
		return {
			ok = true,
			results = {},
		}
	end, results)

	cleanup()

	for _, cleanupError in ipairs(cleanupErrors) do
		table.insert(results, {
			name = "Cleanup.Chapter0Home",
			ok = false,
			message = cleanupError,
			category = "setup",
		})
	end

	local summary = summarize(results)

	print("Suite: " .. suiteName)
	print("Total checks: " .. tostring(summary.total))
	print("Passed checks: " .. tostring(summary.passed))
	print("Failed checks: " .. tostring(summary.failed))
	print("Setup failures: " .. tostring(summary.setupFailures))
	print("Assertion failures: " .. tostring(summary.assertionFailures))

	for _, result in ipairs(results) do
		if not result.ok then
			print(
				"FAIL: "
					.. result.category
					.. ": "
					.. result.name
					.. " - "
					.. tostring(result.message or "no failure message")
			)
		end
	end

	if summary.failed > 0 then
		print("Final: FAIL")

		if shouldError then
			error(suiteName .. " failed.", 0)
		end
	end

	if summary.failed == 0 then
		print("Final: PASS")
	end

	return {
		suite = suiteName,
		total = summary.total,
		passed = summary.passed,
		failed = summary.failed,
		setupFailures = summary.setupFailures,
		assertionFailures = summary.assertionFailures,
		results = results,
	}
end

function Runner.run(suiteName: string)
	return runInternal(suiteName, true)
end

function Runner.runStructured(suiteName: string)
	return runInternal(suiteName, false)
end

return Runner
