--!strict

local Contract = {}

Contract.SchemaVersion = 1
Contract.Phase = 118
Contract.PhaseName = "Chapter 0 Home Observation Integration Runtime Certification Review"
Contract.RunnerId = "chapter0Home.phase118ObservationCertification"
Contract.GateAttribute = "LondonPhase118RunCertification"
Contract.ActiveAttribute = "LondonPhase118CertificationActive"
Contract.Runtime = "RobloxStudio"

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

Contract.CertificationPosture = {
	studioOnly = true,
	explicitGateRequired = true,
	productionAutoRunDisabled = true,
	deterministicRunner = true,
	concurrentRunsRejected = true,
	setupSeparated = true,
	assertionsSeparated = true,
	cleanupSeparated = true,
	upstreamSeparated = true,
	structuredEvidence = true,
	isolatedResults = true,
	runtimeTruthful = true,
	totalsTruthful = true,
	certificationTruthful = true,
	chapterStateRestored = true,
	observationStateRestored = true,
	ownedCleanup = true,
	noNewRemotes = true,
	noPersistence = true,
	noAnalytics = true,
	noTelemetry = true,
	noGameplayChanges = true,
	noChapter1Content = true,
}

Contract.ResultFields = {
	schemaVersion = true,
	phase = true,
	phaseName = true,
	runnerId = true,
	runtime = true,
	studio = true,
	gatePresent = true,
	startedAt = true,
	finishedAt = true,
	durationMs = true,
	status = true,
	setupStatus = true,
	assertionStatus = true,
	cleanupStatus = true,
	upstreamStatus = true,
	totalSuites = true,
	executedSuites = true,
	skippedSuites = true,
	totalChecks = true,
	passedChecks = true,
	failedChecks = true,
	setupFailures = true,
	assertionFailures = true,
	cleanupFailures = true,
	upstreamFailures = true,
	warnings = true,
	failures = true,
	runtimeUnavailable = true,
	productionCertified = true,
	exactSourceCommit = true,
	evidenceId = true,
	nextAction = true,
}

local function isLowerCamelCase(value: string): boolean
	return string.match(value, "^[a-z][A-Za-z0-9]*$") ~= nil
end

local function statusAllowed(status: any): boolean
	for _, allowed in pairs(Contract.Status) do
		if status == allowed then
			return true
		end
	end

	return false
end

local function arrayContains(values: { any }, value: any): boolean
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
		if seen[value] == true then
			return true
		end

		seen[value] = true
	end

	return false
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
		nextAction = nextAction
			or "Review the failing suite and rerun the Studio-gated certification.",
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
		runtime = Contract.Runtime,
		studio = studio,
		gatePresent = gatePresent,
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
		totalChecks = nil,
		passedChecks = nil,
		failedChecks = nil,
		setupFailures = 0,
		assertionFailures = 0,
		cleanupFailures = 0,
		upstreamFailures = 0,
		warnings = {},
		failures = {},
		runtimeUnavailable = false,
		productionCertified = false,
		exactSourceCommit = "",
		evidenceId = Contract.RunnerId .. ".pending",
		nextAction = "Execute the Studio-gated Phase 118 certification runner.",
	}
end

function Contract.validateFailure(failure: any): (boolean, string?)
	if type(failure) ~= "table" then
		return false, "failure must be a table"
	end

	local requiredFields = {
		"suite",
		"check",
		"category",
		"message",
		"source",
		"recoverable",
		"nextAction",
	}

	for _, field in ipairs(requiredFields) do
		if failure[field] == nil then
			return false, "failure missing " .. field
		end
	end

	return true, nil
end

function Contract.validateResult(result: any): (boolean, string?)
	if type(result) ~= "table" then
		return false, "result must be a table"
	end

	for key in pairs(result) do
		if type(key) ~= "string" or Contract.ResultFields[key] ~= true then
			return false, "unsupported result field"
		end

		if not isLowerCamelCase(key) then
			return false, "result field must be lowerCamelCase"
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

	if not statusAllowed(result.status) then
		return false, "invalid status"
	end

	if hasDuplicate(Contract.RequiredSuiteIds) then
		return false, "duplicate required suite ids"
	end

	if type(result.executedSuites) ~= "table" or hasDuplicate(result.executedSuites) then
		return false, "invalid executed suites"
	end

	if type(result.skippedSuites) ~= "table" or hasDuplicate(result.skippedSuites) then
		return false, "invalid skipped suites"
	end

	for _, suiteId in ipairs(result.executedSuites) do
		if not arrayContains(Contract.RequiredSuiteIds, suiteId) then
			return false, "unknown executed suite"
		end
	end

	for _, suiteId in ipairs(result.skippedSuites) do
		if not arrayContains(Contract.RequiredSuiteIds, suiteId) then
			return false, "unknown skipped suite"
		end
	end

	for _, field in ipairs({
		"durationMs",
		"setupFailures",
		"assertionFailures",
		"cleanupFailures",
		"upstreamFailures",
	}) do
		if type(result[field]) ~= "number" or result[field] < 0 then
			return false, "invalid numeric total"
		end
	end

	if result.totalChecks ~= nil and result.passedChecks ~= nil and result.failedChecks ~= nil then
		if result.passedChecks + result.failedChecks ~= result.totalChecks then
			return false, "inconsistent check totals"
		end
	end

	if result.status == Contract.Status.Passed then
		if result.failedChecks ~= 0 or #result.skippedSuites > 0 then
			return false, "passed status cannot have failures or skipped suites"
		end

		if
			result.cleanupStatus ~= Contract.Status.Passed
			or result.upstreamStatus ~= Contract.Status.Passed
		then
			return false, "passed status requires cleanup and upstream pass"
		end

		if result.studio ~= true or result.runtimeUnavailable == true then
			return false, "passed status requires Studio runtime"
		end
	end

	for _, failure in ipairs(result.failures) do
		local ok, reason = Contract.validateFailure(failure)

		if not ok then
			return false, reason
		end
	end

	return true, nil
end

return Contract
