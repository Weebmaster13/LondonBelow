--!strict

local Contract = {}

Contract.SchemaVersion = 1
Contract.Phase = 118
Contract.PhaseName = "Chapter 0 Home Observation Integration Runtime Certification Review"
Contract.RunnerId = "chapter0Home.phase118ObservationCertification"
Contract.RuntimeName = "RobloxStudio"
Contract.Runtime = Contract.RuntimeName
Contract.GateAttribute = "LondonPhase118RunCertification"
Contract.ActiveRunAttribute = "LondonPhase118CertificationActive"
Contract.ActiveAttribute = Contract.ActiveRunAttribute
Contract.NotExecuted = "notExecuted"
Contract.SourceCommitUnavailable = "unavailable"

Contract.Status = {
	NotStarted = "notStarted",
	RuntimeUnavailable = "runtimeUnavailable",
	GateMissing = "gateMissing",
	SetupFailed = "setupFailed",
	AssertionFailed = "assertionFailed",
	CleanupFailed = "cleanupFailed",
	UpstreamFailed = "upstreamFailed",
	Passed = "passed",
	Skipped = "skipped",
}

Contract.StableStatuses = {
	Contract.Status.NotStarted,
	Contract.Status.RuntimeUnavailable,
	Contract.Status.GateMissing,
	Contract.Status.SetupFailed,
	Contract.Status.AssertionFailed,
	Contract.Status.CleanupFailed,
	Contract.Status.UpstreamFailed,
	Contract.Status.Passed,
	Contract.Status.Skipped,
}

Contract.SetupStatusValues = {
	Contract.Status.NotStarted,
	Contract.Status.RuntimeUnavailable,
	Contract.Status.GateMissing,
	Contract.Status.SetupFailed,
	Contract.Status.Passed,
}

Contract.AssertionStatusValues = {
	Contract.Status.NotStarted,
	Contract.Status.AssertionFailed,
	Contract.Status.Passed,
	Contract.Status.Skipped,
}

Contract.CleanupStatusValues = {
	Contract.Status.NotStarted,
	Contract.Status.CleanupFailed,
	Contract.Status.Passed,
}

Contract.UpstreamStatusValues = {
	Contract.Status.NotStarted,
	Contract.Status.SetupFailed,
	Contract.Status.UpstreamFailed,
	Contract.Status.Passed,
	Contract.Status.Skipped,
}

Contract.FailureCategories = {
	Runtime = "runtime",
	Gate = "gate",
	Concurrency = "concurrency",
	Setup = "setup",
	Assertion = "assertion",
	Cleanup = "cleanup",
	Upstream = "upstream",
	Validation = "validation",
	Schema = "schema",
	Dependency = "dependency",
	Internal = "internal",
}

Contract.NextActionValues = {
	RunStudio = "Run the Phase 118 Studio-gated certification runner only when Roblox Studio evidence is available.",
	RuntimeUnavailable = "Run Phase 118 certification from Roblox Studio only.",
	GateMissing = "Set the explicit Phase 118 Workspace gate before running certification.",
	ConcurrentRun = "Wait for the active certification run to finish before rerunning.",
	RecursiveRun = "Stop the recursive certification call and rerun once.",
	ReviewSetupFailure = "Review setup failure and rerun Phase 118 certification in Studio.",
	ReviewFailedSuites = "Review failed Phase 118 suites before certification.",
	ReviewCleanupFailure = "Clear only Phase 118 certification attributes and rerun.",
	CertificationSupported = "Phase 118 runtime evidence supports Production Certification review.",
	RuntimeDeferred = "Roblox Studio runtime execution remains deferred; certification remains Production Candidate.",
}

Contract.RequiredSuiteIds = {
	"Chapter0Home",
	"Chapter0Home.ObservationIntegration",
	"Chapter0Home.Phase117Hardening",
	"Upstream.PlayerExperience",
	"Upstream.InteractionRuntime",
	"Upstream.ObservationEngine",
	"RemoteContract.PlayerExperience",
	"EventBus.PublicationBoundary",
	"Chapter0Home.ResetCleanup",
	"Chapter0Home.DiagnosticsSnapshots",
}

Contract.RequiredSuiteOrdering = Contract.RequiredSuiteIds

Contract.ResultFieldNames = {
	"schemaVersion",
	"phase",
	"phaseName",
	"runnerId",
	"runtime",
	"studio",
	"gatePresent",
	"activeRunPresent",
	"startedAt",
	"finishedAt",
	"durationMs",
	"status",
	"setupStatus",
	"assertionStatus",
	"cleanupStatus",
	"upstreamStatus",
	"totalSuites",
	"executedSuites",
	"skippedSuites",
	"totalChecks",
	"passedChecks",
	"failedChecks",
	"setupFailures",
	"assertionFailures",
	"cleanupFailures",
	"upstreamFailures",
	"warnings",
	"failures",
	"runtimeUnavailable",
	"productionCertified",
	"exactSourceCommit",
	"evidenceId",
	"nextAction",
}

Contract.FailureFieldNames = {
	"suite",
	"check",
	"category",
	"message",
	"expected",
	"actual",
	"source",
	"recoverable",
	"nextAction",
}

Contract.ResultFields = {}
for _, field in ipairs(Contract.ResultFieldNames) do
	Contract.ResultFields[field] = true
end

Contract.FailureFields = {}
for _, field in ipairs(Contract.FailureFieldNames) do
	Contract.FailureFields[field] = true
end

Contract.DiagnosticPostureKeys = {
	"studioOnly",
	"explicitGateRequired",
	"productionAutoRunDisabled",
	"deterministicRunner",
	"exactRunnerIdentity",
	"exactPhaseIdentity",
	"exactSchemaVersion",
	"exactStatusValues",
	"exactSuiteDefinitions",
	"exactSuiteOrdering",
	"exactResultSchema",
	"exactFailureSchema",
	"concurrentRunsRejected",
	"recursiveRunsRejected",
	"activeMarkerOwned",
	"setupSeparated",
	"assertionsSeparated",
	"cleanupSeparated",
	"upstreamSeparated",
	"structuredEvidence",
	"isolatedResults",
	"isolatedFailures",
	"runtimeTruthful",
	"totalsTruthful",
	"certificationTruthful",
	"exactDecisionFunction",
	"cleanupAlwaysAttempted",
	"chapterStateRestored",
	"observationStateRestored",
	"ownedCleanup",
	"rerunSafe",
	"noNewRemotes",
	"noPersistence",
	"noAnalytics",
	"noTelemetry",
	"noGameplayChanges",
	"noChapter1Content",
}

Contract.SnapshotSchemaNames = {
	"runnerIdentity",
	"phaseIdentity",
	"schemaVersion",
	"stableStatuses",
	"requiredSuiteIds",
	"requiredSuiteOrdering",
	"resultFields",
	"failureFields",
	"gateAttribute",
	"activeRunAttribute",
	"certificationRequirements",
	"resultLimits",
	"diagnosticPostureKeys",
	"snapshotSchemaNames",
	"runtimePosture",
	"gatePosture",
	"concurrencyPosture",
	"cleanupPosture",
	"certificationDecisionPosture",
	"nextActionValues",
}

Contract.CertificationRequirements = {
	studioRuntimeConfirmed = true,
	explicitGatePresent = true,
	noConcurrentRun = true,
	setupStatusPassed = true,
	assertionStatusPassed = true,
	cleanupStatusPassed = true,
	upstreamStatusPassed = true,
	allRequiredSuitesExecuted = true,
	noRequiredSuitesSkipped = true,
	failedChecksZero = true,
	allFailureArraysEmpty = true,
	runtimeUnavailableFalse = true,
	sourceEvidencePostureValid = true,
	noBlockingWarnings = true,
	finalStatusPassed = true,
}

Contract.Limits = {
	MaxSuiteCount = 10,
	MaxCheckCount = 10000,
	MaxFailureCount = 1000,
	MaxWarningCount = 1000,
	MaxEvidenceHistory = 8,
	MaxStringLength = 512,
	MaxResultDepth = 8,
	MaxResultEntries = 512,
	MaxDurationMs = 1000 * 60 * 60,
}

Contract.CertificationPosture = {}
for _, key in ipairs(Contract.DiagnosticPostureKeys) do
	Contract.CertificationPosture[key] = true
end

local function isLowerCamelCase(value: string): boolean
	return string.match(value, "^[a-z][A-Za-z0-9]*$") ~= nil
end

local function contains(values: { any }, value: any): boolean
	for _, item in ipairs(values) do
		if item == value then
			return true
		end
	end

	return false
end

local function hasDuplicate(values: { any }): boolean
	local seen = {}

	for _, value in ipairs(values) do
		if type(value) ~= "string" then
			return true
		end

		if seen[value] == true then
			return true
		end

		seen[value] = true
	end

	return false
end

local function isInteger(value: any): boolean
	return type(value) == "number" and value == math.floor(value)
end

local function boundedString(value: any): boolean
	return type(value) == "string" and #value <= Contract.Limits.MaxStringLength
end

local function numericOrNotExecuted(value: any): boolean
	return value == Contract.NotExecuted or (isInteger(value) and value >= 0)
end

local function exactSourceCommitValid(value: any): boolean
	return value == Contract.SourceCommitUnavailable
		or (
			type(value) == "string"
			and string.match(
					value,
					"^[a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9]$"
				)
				~= nil
		)
end

local function exactSourceCommitIsCommit(value: any): boolean
	return type(value) == "string"
		and string.match(
				value,
				"^[a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9]$"
			)
			~= nil
end

local function failureCategoryAllowed(category: any): boolean
	for _, value in pairs(Contract.FailureCategories) do
		if category == value then
			return true
		end
	end

	return false
end

local function nextActionAllowed(value: any): boolean
	for _, allowed in pairs(Contract.NextActionValues) do
		if value == allowed then
			return true
		end
	end

	return false
end

local function valueHasUnsafePayload(
	value: any,
	depth: number,
	entryCount: { count: number },
	seen: { [any]: boolean }
): (boolean, string?)
	local valueType = typeof(value)

	if valueType == "Instance" or valueType == "RBXScriptConnection" then
		return true, "runtime object is not allowed"
	end

	local luaType = type(value)

	if luaType == "function" or luaType == "thread" or luaType == "userdata" then
		return true, "runtime value is not allowed"
	end

	if luaType == "string" and #value > Contract.Limits.MaxStringLength then
		return true, "string exceeds limit"
	end

	if luaType ~= "table" then
		return false, nil
	end

	if depth > Contract.Limits.MaxResultDepth then
		return true, "result depth exceeds limit"
	end

	if seen[value] == true then
		return true, "cyclic table is not allowed"
	end

	seen[value] = true

	for key, child in pairs(value) do
		entryCount.count += 1

		if entryCount.count > Contract.Limits.MaxResultEntries then
			seen[value] = nil
			return true, "result entry count exceeds limit"
		end

		if type(key) ~= "string" and type(key) ~= "number" then
			seen[value] = nil
			return true, "unsupported table key"
		end

		if type(key) == "string" and #key > Contract.Limits.MaxStringLength then
			seen[value] = nil
			return true, "table key exceeds limit"
		end

		local unsafe, reason = valueHasUnsafePayload(child, depth + 1, entryCount, seen)

		if unsafe then
			seen[value] = nil
			return true, reason
		end
	end

	seen[value] = nil
	return false, nil
end

local function safeCopy(value: any, seen: { [any]: boolean }?): any
	local valueType = typeof(value)

	if valueType == "Instance" or valueType == "RBXScriptConnection" then
		return "<runtime-object>"
	end

	if type(value) == "function" or type(value) == "thread" or type(value) == "userdata" then
		return nil
	end

	if type(value) ~= "table" then
		return value
	end

	local activeSeen = seen or {}

	if activeSeen[value] == true then
		return "<cycle>"
	end

	activeSeen[value] = true

	local copy = {}

	for key, child in pairs(value) do
		if type(key) == "string" or type(key) == "number" then
			copy[key] = safeCopy(child, activeSeen)
		end
	end

	activeSeen[value] = nil

	return copy
end

function Contract.safeCopy(value: any): any
	return safeCopy(value, nil)
end

function Contract.makeEvidenceId(startedAt: string): string
	local suffix = string.gsub(startedAt, "[^A-Za-z0-9]", "-")
	return Contract.RunnerId .. "." .. suffix
end

local function timestampValid(value: any): boolean
	return boundedString(value) and string.match(value, "^%d%d%d%d%-%d%d%-%d%dT") ~= nil
end

local function statusAllowed(status: any, values: { string }?): boolean
	return contains(values or Contract.StableStatuses, status)
end

local function arrayPreservesRequiredOrder(values: { string }): boolean
	local lastIndex = 0

	for _, value in ipairs(values) do
		local foundIndex = nil

		for index, requiredId in ipairs(Contract.RequiredSuiteIds) do
			if value == requiredId then
				foundIndex = index
				break
			end
		end

		if foundIndex == nil or foundIndex <= lastIndex then
			return false
		end

		lastIndex = foundIndex
	end

	return true
end

local function blockingWarningPresent(warnings: { any }): boolean
	for _, warning in ipairs(warnings) do
		if type(warning) == "table" then
			if
				warning.blocking == true
				or warning.severity == "blocking"
				or warning.severity == "error"
				or warning.severity == "fatal"
			then
				return true
			end
		elseif type(warning) == "string" and string.match(string.lower(warning), "blocking") then
			return true
		end
	end

	return false
end

function Contract.hasBlockingWarnings(warnings: { any }): boolean
	return blockingWarningPresent(warnings)
end

function Contract.failure(
	suite: string,
	check: string,
	category: string,
	message: string,
	expected: any?,
	actual: any?,
	source: string?,
	recoverable: boolean?,
	nextAction: string?
)
	return {
		suite = suite,
		check = check,
		category = category,
		message = message,
		expected = Contract.safeCopy(expected),
		actual = Contract.safeCopy(actual),
		source = source or Contract.RunnerId,
		recoverable = recoverable ~= false,
		nextAction = nextAction or Contract.NextActionValues.ReviewFailedSuites,
	}
end

function Contract.newResult(
	status: string,
	studio: boolean,
	gatePresent: boolean,
	startedAt: string
)
	return {
		schemaVersion = Contract.SchemaVersion,
		phase = Contract.Phase,
		phaseName = Contract.PhaseName,
		runnerId = Contract.RunnerId,
		runtime = Contract.RuntimeName,
		studio = studio,
		gatePresent = gatePresent,
		activeRunPresent = false,
		startedAt = startedAt,
		finishedAt = "",
		durationMs = 0,
		status = status,
		setupStatus = Contract.Status.NotStarted,
		assertionStatus = Contract.Status.NotStarted,
		cleanupStatus = Contract.Status.NotStarted,
		upstreamStatus = Contract.Status.NotStarted,
		totalSuites = #Contract.RequiredSuiteIds,
		executedSuites = {},
		skippedSuites = Contract.safeCopy(Contract.RequiredSuiteIds),
		totalChecks = Contract.NotExecuted,
		passedChecks = Contract.NotExecuted,
		failedChecks = Contract.NotExecuted,
		setupFailures = 0,
		assertionFailures = 0,
		cleanupFailures = 0,
		upstreamFailures = 0,
		warnings = {},
		failures = {},
		runtimeUnavailable = false,
		productionCertified = false,
		exactSourceCommit = Contract.SourceCommitUnavailable,
		evidenceId = Contract.makeEvidenceId(startedAt),
		nextAction = Contract.NextActionValues.RunStudio,
	}
end

function Contract.validateFailure(failure: any): (boolean, string?)
	if type(failure) ~= "table" then
		return false, "failure must be a table"
	end

	for key in pairs(failure) do
		if type(key) ~= "string" or Contract.FailureFields[key] ~= true then
			return false, "unsupported failure field"
		end

		if not isLowerCamelCase(key) then
			return false, "failure field must be lowerCamelCase"
		end
	end

	for _, field in ipairs(Contract.FailureFieldNames) do
		if failure[field] == nil then
			return false, "failure missing " .. field
		end
	end

	if
		not boundedString(failure.suite)
		or not boundedString(failure.check)
		or not boundedString(failure.message)
		or not boundedString(failure.source)
		or not boundedString(failure.nextAction)
	then
		return false, "failure string field invalid"
	end

	if not failureCategoryAllowed(failure.category) then
		return false, "failure category invalid"
	end

	if type(failure.recoverable) ~= "boolean" then
		return false, "failure recoverable must be boolean"
	end

	if not nextActionAllowed(failure.nextAction) then
		return false, "failure nextAction invalid"
	end

	return true, nil
end

local function validateSuites(result: any): (boolean, string?)
	if result.totalSuites ~= #Contract.RequiredSuiteIds then
		return false, "totalSuites inconsistency"
	end

	if type(result.executedSuites) ~= "table" or hasDuplicate(result.executedSuites) then
		return false, "invalid executed suites"
	end

	if type(result.skippedSuites) ~= "table" or hasDuplicate(result.skippedSuites) then
		return false, "invalid skipped suites"
	end

	if #result.executedSuites + #result.skippedSuites ~= #Contract.RequiredSuiteIds then
		return false, "required suite classification inconsistency"
	end

	local classified = {}

	for _, suiteId in ipairs(result.executedSuites) do
		if not contains(Contract.RequiredSuiteIds, suiteId) then
			return false, "unknown executed suite"
		end

		classified[suiteId] = true
	end

	for _, suiteId in ipairs(result.skippedSuites) do
		if not contains(Contract.RequiredSuiteIds, suiteId) then
			return false, "unknown skipped suite"
		end

		if classified[suiteId] == true then
			return false, "suite cannot be both executed and skipped"
		end

		classified[suiteId] = true
	end

	for _, suiteId in ipairs(Contract.RequiredSuiteIds) do
		if classified[suiteId] ~= true then
			return false, "required suite missing from classification"
		end
	end

	if not arrayPreservesRequiredOrder(result.executedSuites) then
		return false, "executed suite ordering drift"
	end

	if not arrayPreservesRequiredOrder(result.skippedSuites) then
		return false, "skipped suite ordering drift"
	end

	return true, nil
end

local function validateTotals(result: any): (boolean, string?)
	for _, field in ipairs({
		"durationMs",
		"setupFailures",
		"assertionFailures",
		"cleanupFailures",
		"upstreamFailures",
	}) do
		if not isInteger(result[field]) or result[field] < 0 then
			return false, "invalid numeric total"
		end
	end

	if result.durationMs > Contract.Limits.MaxDurationMs then
		return false, "duration exceeds limit"
	end

	for _, field in ipairs({ "totalChecks", "passedChecks", "failedChecks" }) do
		if not numericOrNotExecuted(result[field]) then
			return false, "invalid check total"
		end
	end

	local totalsNotExecuted = result.totalChecks == Contract.NotExecuted
		and result.passedChecks == Contract.NotExecuted
		and result.failedChecks == Contract.NotExecuted

	local totalsExecuted = type(result.totalChecks) == "number"
		and type(result.passedChecks) == "number"
		and type(result.failedChecks) == "number"

	if not totalsNotExecuted and not totalsExecuted then
		return false, "mixed executed and not executed check totals"
	end

	if totalsExecuted then
		if result.totalChecks > Contract.Limits.MaxCheckCount then
			return false, "check total exceeds limit"
		end

		if result.passedChecks + result.failedChecks ~= result.totalChecks then
			return false, "inconsistent check totals"
		end

		if result.failedChecks == 0 and #result.failures > 0 then
			return false, "failure-list count inconsistency"
		end
	elseif
		result.status == Contract.Status.RuntimeUnavailable
		or result.status == Contract.Status.GateMissing
		or result.status == Contract.Status.Skipped
	then
		if #result.executedSuites > 0 then
			return false, "runtimeUnavailable or skipped result cannot execute suites"
		end
	elseif result.status == Contract.Status.Passed then
		return false, "passed status requires executed totals"
	end

	return true, nil
end

function Contract.canProductionCertify(result: any): (boolean, string?)
	if type(result) ~= "table" then
		return false, "result unavailable"
	end

	if result.studio ~= true then
		return false, "Studio runtime was not confirmed"
	end

	if result.gatePresent ~= true then
		return false, "explicit gate was not present"
	end

	if result.activeRunPresent == true then
		return false, "concurrent run posture was active"
	end

	if result.setupStatus ~= Contract.Status.Passed then
		return false, "setup did not pass"
	end

	if result.assertionStatus ~= Contract.Status.Passed then
		return false, "assertions did not pass"
	end

	if result.cleanupStatus ~= Contract.Status.Passed then
		return false, "cleanup did not pass"
	end

	if result.upstreamStatus ~= Contract.Status.Passed then
		return false, "upstream checks did not pass"
	end

	if #result.executedSuites ~= #Contract.RequiredSuiteIds or #result.skippedSuites ~= 0 then
		return false, "not all required suites executed"
	end

	if result.failedChecks ~= 0 then
		return false, "failed checks are present"
	end

	if
		#result.failures > 0
		or result.setupFailures > 0
		or result.assertionFailures > 0
		or result.cleanupFailures > 0
		or result.upstreamFailures > 0
	then
		return false, "failure arrays or counters are not empty"
	end

	if result.runtimeUnavailable == true then
		return false, "runtime unavailable"
	end

	if not exactSourceCommitIsCommit(result.exactSourceCommit) then
		return false, "source evidence posture invalid"
	end

	if type(result.warnings) ~= "table" or blockingWarningPresent(result.warnings) then
		return false, "blocking warning present"
	end

	if result.status ~= Contract.Status.Passed then
		return false, "final status did not pass"
	end

	return true, nil
end

function Contract.validateResult(result: any): (boolean, string?)
	if type(result) ~= "table" then
		return false, "result must be a table"
	end

	local unsafe, unsafeReason = valueHasUnsafePayload(result, 1, { count = 0 }, {})
	if unsafe then
		return false, unsafeReason
	end

	for key in pairs(result) do
		if type(key) ~= "string" or Contract.ResultFields[key] ~= true then
			return false, "unsupported result field"
		end

		if not isLowerCamelCase(key) then
			return false, "result field must be lowerCamelCase"
		end
	end

	for _, field in ipairs(Contract.ResultFieldNames) do
		if result[field] == nil then
			return false, "result missing " .. field
		end
	end

	if result.schemaVersion ~= Contract.SchemaVersion then
		return false, "invalid schemaVersion"
	end

	if result.phase ~= Contract.Phase or result.phaseName ~= Contract.PhaseName then
		return false, "invalid phase identity"
	end

	if result.runnerId ~= Contract.RunnerId then
		return false, "invalid runner identity"
	end

	if result.runtime ~= Contract.RuntimeName then
		return false, "invalid runtime identity"
	end

	if type(result.studio) ~= "boolean" or type(result.gatePresent) ~= "boolean" then
		return false, "invalid runtime or gate posture"
	end

	if type(result.activeRunPresent) ~= "boolean" then
		return false, "invalid active-run posture"
	end

	if not statusAllowed(result.status, Contract.StableStatuses) then
		return false, "invalid status"
	end

	if not statusAllowed(result.setupStatus, Contract.SetupStatusValues) then
		return false, "invalid setup status"
	end

	if not statusAllowed(result.assertionStatus, Contract.AssertionStatusValues) then
		return false, "invalid assertion status"
	end

	if not statusAllowed(result.cleanupStatus, Contract.CleanupStatusValues) then
		return false, "invalid cleanup status"
	end

	if not statusAllowed(result.upstreamStatus, Contract.UpstreamStatusValues) then
		return false, "invalid upstream status"
	end

	if
		hasDuplicate(Contract.RequiredSuiteIds)
		or #Contract.RequiredSuiteIds > Contract.Limits.MaxSuiteCount
	then
		return false, "invalid required suite ids"
	end

	local suiteOk, suiteReason = validateSuites(result)
	if not suiteOk then
		return false, suiteReason
	end

	if type(result.failures) ~= "table" or #result.failures > Contract.Limits.MaxFailureCount then
		return false, "invalid failure list"
	end

	if type(result.warnings) ~= "table" or #result.warnings > Contract.Limits.MaxWarningCount then
		return false, "invalid warning list"
	end

	local totalsOk, totalsReason = validateTotals(result)
	if not totalsOk then
		return false, totalsReason
	end

	if result.status == Contract.Status.Passed then
		if result.failedChecks ~= 0 or #result.skippedSuites > 0 or #result.failures > 0 then
			return false, "passed status cannot have failures or skipped suites"
		end

		if
			result.setupStatus ~= Contract.Status.Passed
			or result.assertionStatus ~= Contract.Status.Passed
			or result.cleanupStatus ~= Contract.Status.Passed
			or result.upstreamStatus ~= Contract.Status.Passed
		then
			return false, "passed status requires all substatus pass"
		end

		if result.studio ~= true or result.runtimeUnavailable == true then
			return false, "passed status requires Studio runtime"
		end
	end

	if
		result.status == Contract.Status.RuntimeUnavailable
		and result.totalChecks ~= Contract.NotExecuted
	then
		return false, "runtimeUnavailable cannot have executed totals"
	end

	if result.status == Contract.Status.GateMissing and result.gatePresent == true then
		return false, "gateMissing cannot have gatePresent true"
	end

	if result.status == Contract.Status.SetupFailed and result.activeRunPresent ~= false then
		return false, "setup failure result must not retain active marker posture"
	end

	if not timestampValid(result.startedAt) or not timestampValid(result.finishedAt) then
		return false, "invalid timestamps"
	end

	if result.finishedAt < result.startedAt then
		return false, "finish before start"
	end

	if result.durationMs < 0 then
		return false, "negative duration"
	end

	if result.evidenceId ~= Contract.makeEvidenceId(result.startedAt) then
		return false, "malformed evidence id"
	end

	if not exactSourceCommitValid(result.exactSourceCommit) then
		return false, "malformed exact source commit"
	end

	if not nextActionAllowed(result.nextAction) then
		return false, "invalid nextAction"
	end

	for _, failure in ipairs(result.failures) do
		local ok, reason = Contract.validateFailure(failure)

		if not ok then
			return false, reason
		end
	end

	local canCertify = Contract.canProductionCertify(result)

	if result.productionCertified ~= canCertify then
		return false, "production certification decision drift"
	end

	return true, nil
end

local function selfCheck(
	name: string,
	ok: boolean,
	detail: string?
): { name: string, ok: boolean, detail: string? }
	return {
		name = name,
		ok = ok,
		detail = detail,
	}
end

function Contract.runSelfChecks()
	local checks = {}

	table.insert(
		checks,
		selfCheck(
			"exactRunnerId",
			Contract.RunnerId == "chapter0Home.phase118ObservationCertification",
			nil
		)
	)
	table.insert(checks, selfCheck("exactPhaseIdentity", Contract.Phase == 118, nil))
	table.insert(
		checks,
		selfCheck(
			"exactPhaseName",
			Contract.PhaseName
				== "Chapter 0 Home Observation Integration Runtime Certification Review",
			nil
		)
	)
	table.insert(checks, selfCheck("exactSchemaVersion", Contract.SchemaVersion == 1, nil))
	table.insert(checks, selfCheck("exactRuntimeName", Contract.RuntimeName == "RobloxStudio", nil))
	table.insert(
		checks,
		selfCheck(
			"exactGateAttribute",
			Contract.GateAttribute == "LondonPhase118RunCertification",
			nil
		)
	)
	table.insert(
		checks,
		selfCheck(
			"exactActiveRunAttribute",
			Contract.ActiveRunAttribute == "LondonPhase118CertificationActive",
			nil
		)
	)
	table.insert(
		checks,
		selfCheck(
			"requiredSuiteCount",
			#Contract.RequiredSuiteIds == Contract.Limits.MaxSuiteCount,
			nil
		)
	)
	table.insert(
		checks,
		selfCheck(
			"requiredSuiteOrdering",
			Contract.RequiredSuiteOrdering == Contract.RequiredSuiteIds,
			nil
		)
	)
	table.insert(checks, selfCheck("stableStatusCount", #Contract.StableStatuses == 9, nil))
	table.insert(checks, selfCheck("resultFieldSchema", #Contract.ResultFieldNames == 33, nil))
	table.insert(checks, selfCheck("failureFieldSchema", #Contract.FailureFieldNames == 9, nil))
	table.insert(
		checks,
		selfCheck(
			"nextActionValues",
			nextActionAllowed(Contract.NextActionValues.RuntimeDeferred),
			nil
		)
	)
	table.insert(checks, selfCheck("postureKeys", #Contract.DiagnosticPostureKeys == 37, nil))
	table.insert(checks, selfCheck("snapshotSchemaNames", #Contract.SnapshotSchemaNames == 20, nil))
	table.insert(
		checks,
		selfCheck(
			"certificationRequirements",
			Contract.CertificationRequirements.finalStatusPassed == true,
			nil
		)
	)

	local result =
		Contract.newResult(Contract.Status.Passed, true, true, "2026-07-16T00:00:00.000Z")
	result.finishedAt = "2026-07-16T00:00:01.000Z"
	result.durationMs = 1000
	result.setupStatus = Contract.Status.Passed
	result.assertionStatus = Contract.Status.Passed
	result.cleanupStatus = Contract.Status.Passed
	result.upstreamStatus = Contract.Status.Passed
	result.executedSuites = Contract.safeCopy(Contract.RequiredSuiteIds)
	result.skippedSuites = {}
	result.totalChecks = 10
	result.passedChecks = 10
	result.failedChecks = 0
	result.nextAction = Contract.NextActionValues.CertificationSupported
	result.productionCertified = true
	result.exactSourceCommit = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	result.evidenceId = Contract.makeEvidenceId(result.startedAt)

	local validResult = Contract.validateResult(result)
	table.insert(checks, selfCheck("validPassingResult", validResult, nil))

	local drift = Contract.safeCopy(result)
	drift.extraField = true
	table.insert(
		checks,
		selfCheck("unauthorizedFieldRejection", Contract.validateResult(drift) == false, nil)
	)

	local skipped = Contract.safeCopy(result)
	skipped.skippedSuites = { Contract.RequiredSuiteIds[1] }
	table.insert(
		checks,
		selfCheck("passedWithSkippedSuiteRejection", Contract.validateResult(skipped) == false, nil)
	)

	local failed = Contract.safeCopy(result)
	failed.failedChecks = 1
	failed.passedChecks = 9
	failed.productionCertified = false
	table.insert(
		checks,
		selfCheck("certifiedWithFailureRejection", Contract.validateResult(failed) == false, nil)
	)

	local unsafe = Contract.safeCopy(result)
	unsafe.failures = {}
	unsafe.failures[1] = Contract.failure(
		"Suite",
		"Check",
		Contract.FailureCategories.Assertion,
		"failure",
		true,
		false
	)
	unsafe.failures[1].callback = function() end
	table.insert(
		checks,
		selfCheck(
			"runtimeObjectContaminationRejection",
			Contract.validateResult(unsafe) == false,
			nil
		)
	)

	return {
		ok = true,
		results = checks,
	}
end

return Contract
