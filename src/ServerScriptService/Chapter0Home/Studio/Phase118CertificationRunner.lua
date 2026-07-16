--!strict
--[[
	Manual Roblox Studio runtime-certification review entry point for Phase 118.

	This runner does not execute automatically. It requires Studio and an explicit
	Workspace gate before invoking the shared Chapter 0 Home certification runner.
]]

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Contract = require(script.Parent.Phase118CertificationContract)
local SharedRunner = require(script.Parent.Chapter0HomeStudioSelfCheckRunner)

local Runner = {}

local function now(): string
	return DateTime.now():ToIsoDate()
end

local function finish(result: any, startedClock: number, status: string)
	result.finishedAt = now()
	result.durationMs = math.max(0, math.floor((os.clock() - startedClock) * 1000))
	result.status = status
	result.evidenceId = Contract.RunnerId .. "." .. tostring(result.startedAt)

	local valid, reason = Contract.validateResult(result)

	if not valid then
		error("Phase 118 certification result invalid: " .. tostring(reason), 0)
	end

	return Contract.safeCopy(result)
end

local function printSummary(result: any)
	print("Suite: " .. Contract.PhaseName)
	print("Runner: " .. Contract.RunnerId)
	print("Status: " .. tostring(result.status))
	print("Setup status: " .. tostring(result.setupStatus))
	print("Assertion status: " .. tostring(result.assertionStatus))
	print("Cleanup status: " .. tostring(result.cleanupStatus))
	print("Upstream status: " .. tostring(result.upstreamStatus))
	print("Total suites: " .. tostring(result.totalSuites))
	print("Executed suites: " .. tostring(#result.executedSuites))
	print("Skipped suites: " .. tostring(#result.skippedSuites))
	print("Total checks: " .. tostring(result.totalChecks or "not executed"))
	print("Passed checks: " .. tostring(result.passedChecks or "not executed"))
	print("Failed checks: " .. tostring(result.failedChecks or "not executed"))
	print("Production certified: " .. tostring(result.productionCertified))
	print("Next action: " .. tostring(result.nextAction))

	for _, failure in ipairs(result.failures) do
		print(
			"FAIL: "
				.. tostring(failure.category)
				.. ": "
				.. tostring(failure.suite)
				.. " :: "
				.. tostring(failure.check)
				.. " - "
				.. tostring(failure.message)
		)
	end
end

function Runner.run()
	local startedAt = now()
	local startedClock = os.clock()
	local studio = RunService:IsStudio()
	local gatePresent = Workspace:GetAttribute(Contract.GateAttribute) == true
	local result = Contract.newResult(Contract.Status.NotStarted, studio, gatePresent, startedAt)

	if not studio then
		result.runtimeUnavailable = true
		result.setupStatus = Contract.Status.RuntimeUnavailable
		result.nextAction = "Run Phase 118 certification from Roblox Studio only."
		table.insert(
			result.failures,
			Contract.failure(
				"Phase118.Setup",
				"studioRuntime",
				"setup",
				"Phase 118 certification runner is Studio-only.",
				true,
				false,
				Contract.RunnerId,
				true,
				result.nextAction
			)
		)
		result.setupFailures = 1
		result = finish(result, startedClock, Contract.Status.RuntimeUnavailable)
		printSummary(result)
		error("Phase 118 certification runtime unavailable.", 0)
	end

	if not gatePresent then
		result.setupStatus = Contract.Status.GateMissing
		result.nextAction =
			"Set the explicit Phase 118 Workspace gate before running certification."
		table.insert(
			result.failures,
			Contract.failure(
				"Phase118.Setup",
				"explicitGate",
				"setup",
				"Missing Workspace attribute " .. Contract.GateAttribute .. " = true.",
				true,
				false,
				Contract.RunnerId,
				true,
				result.nextAction
			)
		)
		result.setupFailures = 1
		result = finish(result, startedClock, Contract.Status.GateMissing)
		printSummary(result)
		error("Phase 118 certification gate missing.", 0)
	end

	if Workspace:GetAttribute(Contract.ActiveAttribute) == true then
		result.setupStatus = Contract.Status.SetupFailed
		result.nextAction = "Wait for the active certification run to finish before rerunning."
		table.insert(
			result.failures,
			Contract.failure(
				"Phase118.Setup",
				"concurrentRun",
				"setup",
				"Phase 118 certification is already active.",
				false,
				true,
				Contract.RunnerId,
				true,
				result.nextAction
			)
		)
		result.setupFailures = 1
		result = finish(result, startedClock, Contract.Status.SetupFailed)
		printSummary(result)
		error("Phase 118 certification already active.", 0)
	end

	Workspace:SetAttribute(Contract.ActiveAttribute, true)

	local ok, sharedResult = pcall(function()
		return SharedRunner.runStructured(Contract.PhaseName)
	end)

	local cleanupOk, cleanupError = pcall(function()
		Workspace:SetAttribute(Contract.ActiveAttribute, nil)
		Workspace:SetAttribute(Contract.GateAttribute, nil)
	end)

	result.executedSuites = if ok then Contract.safeCopy(Contract.RequiredSuiteIds) else {}
	result.skippedSuites = if ok then {} else Contract.safeCopy(Contract.RequiredSuiteIds)
	result.cleanupStatus = if cleanupOk
		then Contract.Status.Passed
		else Contract.Status.CleanupFailed
	result.cleanupFailures = if cleanupOk then 0 else 1

	if not cleanupOk then
		table.insert(
			result.failures,
			Contract.failure(
				"Phase118.Cleanup",
				"restoreWorkspaceGate",
				"cleanup",
				tostring(cleanupError),
				"gate and active marker cleared",
				"cleanup failed",
				Contract.RunnerId,
				true,
				"Clear only Phase 118 certification attributes and rerun."
			)
		)
	end

	if ok and type(sharedResult) == "table" then
		result.setupStatus = if sharedResult.setupFailures == 0
			then Contract.Status.Passed
			else Contract.Status.SetupFailed
		result.assertionStatus = if sharedResult.failed == 0
			then Contract.Status.Passed
			else Contract.Status.AssertionFailed
		result.upstreamStatus = if sharedResult.setupFailures == 0
				and sharedResult.failed == 0
			then Contract.Status.Passed
			elseif sharedResult.setupFailures > 0 then Contract.Status.SetupFailed
			else Contract.Status.UpstreamFailed
		result.totalChecks = sharedResult.total
		result.passedChecks = sharedResult.passed
		result.failedChecks = sharedResult.failed
		result.setupFailures = sharedResult.setupFailures or 0
		result.assertionFailures = sharedResult.assertionFailures or sharedResult.failed or 0
		result.upstreamFailures = 0
		result.productionCertified = result.failedChecks == 0 and cleanupOk
		result.nextAction = if result.productionCertified
			then "Phase 118 runtime evidence supports Production Certification review."
			else "Review failed Phase 118 suites before certification."
	else
		result.setupStatus = Contract.Status.Passed
		result.assertionStatus = Contract.Status.AssertionFailed
		result.upstreamStatus = Contract.Status.Skipped
		result.totalChecks = nil
		result.passedChecks = nil
		result.failedChecks = nil
		result.assertionFailures += 1
		result.productionCertified = false
		result.nextAction = "Review setup failure and rerun Phase 118 certification in Studio."
		table.insert(
			result.failures,
			Contract.failure(
				"Phase118.Execution",
				"sharedRunner",
				"assertion",
				tostring(sharedResult),
				"shared runner completes",
				"shared runner failed",
				Contract.RunnerId,
				true,
				result.nextAction
			)
		)
	end

	local finalStatus = Contract.Status.Passed

	if not ok or result.setupStatus == Contract.Status.SetupFailed then
		finalStatus = Contract.Status.SetupFailed
	elseif result.upstreamStatus == Contract.Status.UpstreamFailed then
		finalStatus = Contract.Status.UpstreamFailed
	elseif result.assertionStatus == Contract.Status.AssertionFailed then
		finalStatus = Contract.Status.AssertionFailed
	elseif result.cleanupStatus == Contract.Status.CleanupFailed then
		finalStatus = Contract.Status.CleanupFailed
	end

	result = finish(result, startedClock, finalStatus)
	printSummary(result)

	if result.productionCertified ~= true then
		error("Phase 118 certification did not pass.", 0)
	end

	return result
end

function Runner.inspect()
	return {
		provider = Contract.RunnerId,
		phase = Contract.Phase,
		phaseName = Contract.PhaseName,
		runnerId = Contract.RunnerId,
		gateAttribute = Contract.GateAttribute,
		activeAttribute = Contract.ActiveAttribute,
		phase118CertificationPosture = Contract.safeCopy(Contract.CertificationPosture),
	}
end

function Runner.getSnapshot()
	return {
		provider = Contract.RunnerId,
		phase = Contract.Phase,
		phaseName = Contract.PhaseName,
		runnerId = Contract.RunnerId,
		schemaVersion = Contract.SchemaVersion,
		statusValues = Contract.safeCopy(Contract.Status),
		requiredSuiteIds = Contract.safeCopy(Contract.RequiredSuiteIds),
		resultFields = Contract.safeCopy(Contract.ResultFields),
		gatePosture = {
			gateAttribute = Contract.GateAttribute,
			activeAttribute = Contract.ActiveAttribute,
			explicitGateRequired = true,
			productionAutoRunDisabled = true,
		},
		runtimePosture = {
			studioOnly = true,
			runtime = Contract.Runtime,
			runtimeUnavailableIsNotPassing = true,
		},
		certificationDecision = {
			productionCertifiedRequiresStudioExecution = true,
			productionCertifiedRequiresZeroFailures = true,
			productionCertifiedRequiresCleanupSuccess = true,
			productionCertifiedRequiresUpstreamSuccess = true,
		},
		nextAction = "Run the Phase 118 Studio-gated certification runner only when Roblox Studio evidence is available.",
	}
end

return Runner
