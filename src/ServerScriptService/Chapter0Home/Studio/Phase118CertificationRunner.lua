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
local activeRunDepth = 0

local function now(): string
	return DateTime.now():ToIsoDate()
end

local function finish(result: any, startedClock: number, status: string)
	result.finishedAt = now()
	result.durationMs = math.max(0, math.floor((os.clock() - startedClock) * 1000))
	result.status = status
	result.evidenceId = Contract.makeEvidenceId(result.startedAt)

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
	local activeRunPresent = Workspace:GetAttribute(Contract.ActiveRunAttribute) == true
	local result = Contract.newResult(Contract.Status.NotStarted, studio, gatePresent, startedAt)
	result.activeRunPresent = activeRunPresent

	if not studio then
		result.runtimeUnavailable = true
		result.setupStatus = Contract.Status.RuntimeUnavailable
		result.nextAction = Contract.NextActionValues.RuntimeUnavailable
		table.insert(
			result.failures,
			Contract.failure(
				"Phase118.Setup",
				"studioRuntime",
				Contract.FailureCategories.Runtime,
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
		result.nextAction = Contract.NextActionValues.GateMissing
		table.insert(
			result.failures,
			Contract.failure(
				"Phase118.Setup",
				"explicitGate",
				Contract.FailureCategories.Gate,
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

	if activeRunDepth > 0 then
		result.setupStatus = Contract.Status.SetupFailed
		result.nextAction = Contract.NextActionValues.RecursiveRun
		table.insert(
			result.failures,
			Contract.failure(
				"Phase118.Setup",
				"recursiveRun",
				Contract.FailureCategories.Concurrency,
				"Phase 118 certification cannot be invoked recursively.",
				false,
				activeRunDepth,
				Contract.RunnerId,
				true,
				result.nextAction
			)
		)
		result.setupFailures = 1
		result = finish(result, startedClock, Contract.Status.SetupFailed)
		printSummary(result)
		error("Phase 118 certification recursive invocation rejected.", 0)
	end

	if activeRunPresent then
		result.setupStatus = Contract.Status.SetupFailed
		result.nextAction = Contract.NextActionValues.ConcurrentRun
		result.activeRunPresent = false
		table.insert(
			result.failures,
			Contract.failure(
				"Phase118.Setup",
				"concurrentRun",
				Contract.FailureCategories.Concurrency,
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

	local setupOk, setupError = pcall(function()
		if type(SharedRunner.runStructured) ~= "function" then
			error("Chapter0HomeStudioSelfCheckRunner.runStructured missing", 0)
		end

		if
			type(Contract.validateResult) ~= "function"
			or type(Contract.canProductionCertify) ~= "function"
		then
			error("Phase118CertificationContract validation functions missing", 0)
		end
	end)

	if not setupOk then
		result.setupStatus = Contract.Status.SetupFailed
		result.nextAction = Contract.NextActionValues.ReviewSetupFailure
		table.insert(
			result.failures,
			Contract.failure(
				"Phase118.Setup",
				"moduleResolution",
				Contract.FailureCategories.Setup,
				tostring(setupError),
				"required certification modules resolve",
				"setup failed",
				Contract.RunnerId,
				true,
				result.nextAction
			)
		)
		result.setupFailures = 1
		result = finish(result, startedClock, Contract.Status.SetupFailed)
		printSummary(result)
		error("Phase 118 certification setup failed.", 0)
	end

	activeRunDepth += 1
	Workspace:SetAttribute(Contract.ActiveRunAttribute, true)

	local ok, sharedResult = pcall(function()
		return SharedRunner.runStructured(Contract.PhaseName)
	end)

	local cleanupOk, cleanupError = pcall(function()
		if Workspace:GetAttribute(Contract.ActiveRunAttribute) == true then
			Workspace:SetAttribute(Contract.ActiveRunAttribute, nil)
		end

		if Workspace:GetAttribute(Contract.GateAttribute) == true then
			Workspace:SetAttribute(Contract.GateAttribute, nil)
		end
	end)
	activeRunDepth = math.max(0, activeRunDepth - 1)
	result.activeRunPresent = false

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
				Contract.FailureCategories.Cleanup,
				tostring(cleanupError),
				"gate and active marker cleared",
				"cleanup failed",
				Contract.RunnerId,
				true,
				Contract.NextActionValues.ReviewCleanupFailure
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
		result.nextAction = if sharedResult.failed == 0 and cleanupOk
			then Contract.NextActionValues.CertificationSupported
			else Contract.NextActionValues.ReviewFailedSuites
	else
		result.setupStatus = Contract.Status.Passed
		result.assertionStatus = Contract.Status.AssertionFailed
		result.upstreamStatus = Contract.Status.Skipped
		result.totalChecks = Contract.NotExecuted
		result.passedChecks = Contract.NotExecuted
		result.failedChecks = Contract.NotExecuted
		result.assertionFailures += 1
		result.nextAction = Contract.NextActionValues.ReviewSetupFailure
		table.insert(
			result.failures,
			Contract.failure(
				"Phase118.Execution",
				"sharedRunner",
				Contract.FailureCategories.Assertion,
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

	result.status = finalStatus
	result.productionCertified = Contract.canProductionCertify(result)
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
		activeAttribute = Contract.ActiveRunAttribute,
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
		stableStatuses = Contract.safeCopy(Contract.StableStatuses),
		requiredSuiteIds = Contract.safeCopy(Contract.RequiredSuiteIds),
		requiredSuiteOrdering = Contract.safeCopy(Contract.RequiredSuiteOrdering),
		resultFields = Contract.safeCopy(Contract.ResultFields),
		resultFieldNames = Contract.safeCopy(Contract.ResultFieldNames),
		failureFields = Contract.safeCopy(Contract.FailureFields),
		failureFieldNames = Contract.safeCopy(Contract.FailureFieldNames),
		diagnosticPostureKeys = Contract.safeCopy(Contract.DiagnosticPostureKeys),
		snapshotSchemaNames = Contract.safeCopy(Contract.SnapshotSchemaNames),
		certificationRequirements = Contract.safeCopy(Contract.CertificationRequirements),
		resultLimits = Contract.safeCopy(Contract.Limits),
		nextActionValues = Contract.safeCopy(Contract.NextActionValues),
		gatePosture = {
			gateAttribute = Contract.GateAttribute,
			activeAttribute = Contract.ActiveRunAttribute,
			explicitGateRequired = true,
			productionAutoRunDisabled = true,
		},
		runtimePosture = {
			studioOnly = true,
			runtime = Contract.RuntimeName,
			runtimeUnavailableIsNotPassing = true,
		},
		concurrencyPosture = {
			concurrentRunsRejected = true,
			recursiveRunsRejected = true,
			activeMarkerOwned = true,
		},
		cleanupPosture = {
			cleanupAlwaysAttempted = true,
			ownedGateCleared = true,
			ownedActiveMarkerCleared = true,
		},
		certificationDecision = {
			productionCertifiedRequiresStudioExecution = true,
			productionCertifiedRequiresZeroFailures = true,
			productionCertifiedRequiresCleanupSuccess = true,
			productionCertifiedRequiresUpstreamSuccess = true,
			exactDecisionFunction = "Phase118CertificationContract.canProductionCertify",
		},
		nextAction = Contract.NextActionValues.RunStudio,
	}
end

return Runner
