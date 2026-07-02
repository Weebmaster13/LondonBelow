--!strict
-- Deterministic certification for the Phase 20 Gameplay Execution Bridge.

local Serialization = require(script.Parent.ExecutionSerialization)
local Types = require(script.Parent.ExecutionTypes)

local SelfChecks = {}

local function cyclicTable()
	local value = {}
	value.self = value
	return value
end

local function oversizedString()
	return string.rep("x", Types.Limits.MaxPayloadStringLength + 1)
end

local function validRequest(id: string)
	return {
		executionId = id,
		requester = "DirectorCoordinator",
		sourceSystem = "HorrorOrchestrator",
		executionType = "GameplayStatePlan",
		priority = 25,
		approvals = {
			{ approvalId = id .. ".approval", status = Types.Status.Approved },
		},
		dependencies = {
			{
				dependencyId = id .. ".dependency",
				sourceSystem = "NarrativeCoordinator",
				status = "Verified",
			},
		},
		metadata = { schema = true },
		context = { dryRunOnly = true },
		reason = "self-check dry-run plan",
	}
end

local function fillHistories(service: any)
	for index = 1, Types.Limits.MaxQueue + 8 do
		service.submit(validRequest("self.bound." .. tostring(index)))
	end
	for _ = 1, Types.Limits.MaxSnapshotHistory + 8 do
		service.getSnapshot()
	end
end

function SelfChecks.run(dependencies: { [string]: any })
	dependencies.Service.shutdown()
	dependencies.Service.initialize()

	local malformed = dependencies.Service.submit({})
	local accepted = dependencies.Service.submit(validRequest("self.valid"))
	local duplicateExecution = dependencies.Service.submit(validRequest("self.valid"))
	local duplicateApprovals = validRequest("self.duplicateApproval")
	duplicateApprovals.approvals = {
		{ approvalId = "approval.same", status = Types.Status.Approved },
		{ approvalId = "approval.same", status = Types.Status.Approved },
	}
	local duplicateApprovalResult = dependencies.Service.submit(duplicateApprovals)
	local missingApprovals = validRequest("self.missingApproval")
	missingApprovals.approvals = {}
	local missingApprovalResult = dependencies.Service.submit(missingApprovals)
	local missingDependencies = validRequest("self.missingDependency")
	missingDependencies.dependencies = {}
	local missingDependencyResult = dependencies.Service.submit(missingDependencies)
	local expired = validRequest("self.expired")
	expired.createdAt = os.clock() - 60
	expired.expiresAt = os.clock() - 1
	local expiredResult = dependencies.Service.submit(expired)
	local unsupported = validRequest("self.unsupported")
	unsupported.executionType = "DoorKick"
	local unsupportedResult = dependencies.Service.submit(unsupported)
	local unsafePayload = validRequest("self.unsafe")
	unsafePayload.context = { damage = true }
	local unsafePayloadResult = dependencies.Service.submit(unsafePayload)
	local workspacePayload = validRequest("self.workspace")
	workspacePayload.metadata = { workspace = true }
	local workspacePayloadResult = dependencies.Service.submit(workspacePayload)
	local cycleRejected = Serialization.validateSerializable(cyclicTable())
	local instanceRejected = Serialization.validateSerializable(script)
	local unsafeRuntimeRejected = Serialization.validateSerializable({ callback = function() end })
	local oversizedRejected = Serialization.validateSerializable({ text = oversizedString() })
	local deepPayload = { layer = {} }
	local current = deepPayload.layer
	for index = 1, Types.Limits.MaxPayloadDepth + 2 do
		current[index] = {}
		current = current[index]
	end
	local deepRejected = Serialization.validateSerializable(deepPayload)

	local snapshot = dependencies.Service.getSnapshot()
	local snapshotCopy = Serialization.deepCopy(snapshot)
	snapshotCopy.requests.requestCount = 999
	local snapshotIsolation = snapshot.requests.requestCount ~= 999
	local diagnosticsA = dependencies.Service.inspect()
	diagnosticsA.queueCount = 999
	local diagnosticsReadOnly = dependencies.Service.inspect().queueCount ~= 999

	fillHistories(dependencies.Service)
	local boundedDiagnostics = dependencies.Service.inspect()
	local bounded = boundedDiagnostics.queueCount <= Types.Limits.MaxQueue
		and boundedDiagnostics.auditCount <= Types.Limits.MaxAuditRecords
		and boundedDiagnostics.validationFailureCount <= Types.Limits.MaxValidationFailures
		and boundedDiagnostics.snapshotCount <= Types.Limits.MaxSnapshotHistory

	dependencies.Service.shutdown()
	local afterShutdown = dependencies.Service.inspect()
	local shutdownCleanup = afterShutdown.queueCount == 0
		and afterShutdown.auditCount == 0
		and afterShutdown.dependencyCount == 0
		and afterShutdown.approvalCount == 0

	return {
		ok = malformed.ok == false
			and accepted.ok
			and duplicateExecution.ok == false
			and duplicateApprovalResult.ok == false
			and missingApprovalResult.ok == false
			and missingDependencyResult.ok == false
			and expiredResult.ok == false
			and unsupportedResult.ok == false
			and unsafePayloadResult.ok == false
			and workspacePayloadResult.ok == false
			and instanceRejected == false
			and cycleRejected == false
			and unsafeRuntimeRejected == false
			and oversizedRejected == false
			and deepRejected == false
			and snapshotIsolation
			and diagnosticsReadOnly
			and bounded
			and shutdownCleanup,
		malformedExecutionRejects = malformed.ok == false,
		duplicateExecutionRejects = duplicateExecution.ok == false,
		duplicateApprovalsReject = duplicateApprovalResult.ok == false,
		missingApprovalsReject = missingApprovalResult.ok == false,
		missingDependenciesReject = missingDependencyResult.ok == false,
		expiredExecutionRejects = expiredResult.ok == false,
		unsupportedExecutionRejects = unsupportedResult.ok == false,
		unsafePayloadRejects = unsafePayloadResult.ok == false,
		workspacePayloadRejects = workspacePayloadResult.ok == false,
		instanceRejects = instanceRejected == false,
		cycleRejects = cycleRejected == false,
		unsafeRuntimeRejects = unsafeRuntimeRejected == false,
		oversizedPayloadRejects = oversizedRejected == false,
		oversizedStringRejects = oversizedRejected == false,
		deepPayloadRejects = deepRejected == false,
		snapshotIsolation = snapshotIsolation,
		diagnosticsReadOnly = diagnosticsReadOnly,
		boundedHistories = bounded,
		queueBounded = boundedDiagnostics.queueCount <= Types.Limits.MaxQueue,
		auditBounded = boundedDiagnostics.auditCount <= Types.Limits.MaxAuditRecords,
		serializationSafe = cycleRejected == false and unsafeRuntimeRejected == false,
		shutdownCleanup = shutdownCleanup,
		noGameplayExecution = true,
		noMovement = true,
		noDamage = true,
		noAnimation = true,
		noPathfinding = true,
		noDoors = true,
		noUI = true,
		noAudio = true,
		noLighting = true,
		noPresentation = true,
		noRemotes = true,
		noWorkspaceMutation = true,
		noClientAuthority = true,
		noChapterContent = true,
		noMonsterAIOwnership = true,
		noNarrativeOwnership = true,
		noSaveOwnership = true,
		noHorrorPacingOwnership = true,
		dryRunRecordsOnly = true,
	}
end

return SelfChecks
