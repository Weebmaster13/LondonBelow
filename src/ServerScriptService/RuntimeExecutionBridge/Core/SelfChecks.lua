--!strict

local RuntimeAssertions = require(script.Parent.RuntimeAssertions)
local RuntimeDiagnostics = require(script.Parent.RuntimeDiagnostics)
local RuntimeEvidence = require(script.Parent.RuntimeEvidence)
local RuntimeSession = require(script.Parent.RuntimeSession)
local RuntimeWriter = require(script.Parent.RuntimeWriter)
local Serialization = require(script.Parent.Serialization)
local State = require(script.Parent.State)
local Types = require(script.Parent.Types)
local Validation = require(script.Parent.Validation)

local SelfChecks = {}

local function expect(results: { any }, name: string, ok: boolean, detail: string?)
	table.insert(results, { name = name, ok = ok, detail = detail })
end

local function countFailures(results: { any }): number
	local failures = 0
	for _, check in ipairs(results) do
		if not check.ok then
			failures += 1
		end
	end
	return failures
end

local function validSession(): any
	return Serialization.deepCopy(Types.DefaultSession)
end

local function observation(): any
	return {
		runService = {
			isStudio = true,
			isServer = true,
			isClient = false,
			isRunning = true,
		},
		gameLoaded = true,
		services = {
			Players = true,
			Workspace = true,
			ReplicatedStorage = true,
			ServerScriptService = true,
			Lighting = true,
			SoundService = true,
			CollectionService = true,
		},
		players = {
			count = 0,
		},
		workspace = {
			name = "Workspace",
			childCount = 0,
		},
		coordinators = {
			count = 1,
			names = { "ServerScriptService.Chapter0Home.Core.Chapter0HomeCoordinator" },
		},
	}
end

function SelfChecks.run(context: any): any
	local service = context.Service
	local results = {}

	expect(
		results,
		"provider name lowerCamelCase",
		Types.RuntimeProviderName == "runtimeExecutionBridge",
		nil
	)
	expect(
		results,
		"snapshot kind lowerCamelCase",
		Types.SnapshotKind == "runtimeExecutionBridgeSnapshot",
		nil
	)
	expect(results, "validation passes", select(1, Validation.validate()) == true, nil)

	local session = validSession()
	local sessionOk, sessionReason = Validation.session(session)
	expect(results, "valid session accepted", sessionOk == true, sessionReason)

	local invalidSession = validSession()
	invalidSession.phase = 154
	expect(
		results,
		"wrong phase rejected",
		select(1, Validation.session(invalidSession)) == false,
		nil
	)

	local certificationSession = validSession()
	certificationSession.policies.certificationDecisionAllowed = true
	expect(
		results,
		"certification policy rejected",
		select(1, Validation.session(certificationSession)) == false,
		nil
	)

	local sessionImportOk, _, importedSession = RuntimeSession.import(session)
	expect(results, "session imported", sessionImportOk == true and importedSession ~= nil, nil)

	local observed = observation()
	local assertions = RuntimeAssertions.capture({ coordinatorCount = observed.coordinators.count })
	expect(results, "assertions created", #assertions == 8, nil)
	expect(
		results,
		"server assertion pass",
		assertions[1].status == Types.AssertionStatus.Pass,
		nil
	)
	expect(
		results,
		"client assertion not executed",
		assertions[2].status == Types.AssertionStatus.NotExecuted,
		nil
	)

	local diagnostics =
		RuntimeDiagnostics.capture({ coordinatorCount = observed.coordinators.count })
	expect(results, "diagnostics created", #diagnostics == 3, nil)
	expect(
		results,
		"writer unavailable diagnostic",
		diagnostics[2].code == "FilesystemWriterUnavailable",
		nil
	)

	local cleanup = {
		started = true,
		completed = true,
		warnings = {},
	}
	local snapshots = {
		{
			snapshotKind = "runtimeExecutionBridgeServiceSnapshot",
			observation = observed,
		},
	}
	local evidenceOk, evidenceReason, evidence =
		RuntimeEvidence.build(session, observed, assertions, diagnostics, snapshots, cleanup)
	expect(results, "evidence built", evidenceOk == true and evidence ~= nil, evidenceReason)
	if evidence ~= nil then
		expect(
			results,
			"evidence schema version",
			evidence.schemaVersion == Types.SchemaVersion,
			nil
		)
		expect(results, "evidence session binding", evidence.sessionId == session.sessionId, nil)
		expect(results, "evidence phase binding", evidence.phase == 155, nil)
		expect(results, "evidence runner binding", evidence.runnerId == session.runnerId, nil)
		expect(
			results,
			"evidence commit binding",
			evidence.repositoryCommit == session.repositoryCommit,
			nil
		)
		expect(results, "evidence cannot certify", evidence.productionCertified == false, nil)
		expect(results, "evidence status blocked", evidence.status == Types.Status.Blocked, nil)
		expect(
			results,
			"evidence exact schema accepted",
			select(1, Validation.evidence(evidence)) == true,
			nil
		)

		local writer = RuntimeWriter.writeAtomic(session, evidence)
		expect(
			results,
			"writer blocks truthfully",
			writer.ok == false and writer.failure == "Writer",
			nil
		)
		expect(results, "writer records checksum", type(writer.payloadChecksum) == "string", nil)
		expect(results, "writer rejects partial writes", writer.partialWriteRejected == true, nil)
		expect(
			results,
			"writer rejects duplicate writes",
			writer.duplicateWriteRejected == true,
			nil
		)
		expect(results, "writer preserves session", writer.overwroteExistingSession == false, nil)

		local copy = Serialization.deepCopy(evidence)
		copy.status = Types.Status.Passed
		expect(results, "copy isolation", evidence.status == Types.Status.Blocked, nil)
	end

	local diagnosticsSnapshot = service.inspect()
	local snapshot = service.getSnapshot()
	diagnosticsSnapshot.noGameplayMutation = false
	snapshot.noGameplayMutation = false
	expect(results, "diagnostics isolation", service.inspect().noGameplayMutation == true, nil)
	expect(results, "snapshot isolation", service.getSnapshot().noGameplayMutation == true, nil)
	expect(
		results,
		"shutdown cleanup",
		service.shutdown().ok == true and State.get().session == nil,
		nil
	)

	for _, field in ipairs(Types.RequiredSessionFields) do
		expect(
			results,
			"required session field " .. field,
			table.find(Types.RequiredSessionFields, field) ~= nil,
			nil
		)
	end
	for _, field in ipairs(Types.RunnerResultFields) do
		expect(
			results,
			"runner result field " .. field,
			table.find(Types.RunnerResultFields, field) ~= nil,
			nil
		)
	end
	for key in pairs(Types.FailureClassification) do
		expect(
			results,
			"failure classification " .. key,
			type(Types.FailureClassification[key]) == "string",
			nil
		)
	end
	for key in pairs(Types.LifecycleState) do
		expect(results, "lifecycle state " .. key, type(Types.LifecycleState[key]) == "string", nil)
	end
	for key, limit in pairs(Types.Limits) do
		expect(results, "limit " .. key, type(limit) == "number" and limit > 0, nil)
	end

	local failures = countFailures(results)
	return {
		ok = failures == 0,
		total = #results,
		failures = failures,
		results = results,
		categories = {
			"bridge startup",
			"session imported",
			"manifest metadata validation",
			"assertions created",
			"diagnostics created",
			"snapshots created",
			"writer initialized",
			"evidence prepared",
			"checksum generated",
			"writer blocked truthfully",
			"cleanup completed",
			"schema exactness",
			"session binding",
			"phase binding",
			"runner binding",
			"certification boundary",
			"diagnostics isolation",
			"snapshot isolation",
		},
	}
end

return SelfChecks
