--!strict
-- Deterministic certification for Phase 22 Presentation Runtime Foundation.

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

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
		presentationId = id,
		requester = "DirectorCoordinator",
		sourceSystem = "PresentationSelfCheck",
		presentationType = Types.PresentationType.SystemPresentationPlan,
		priority = 20,
		approvals = {
			{ approvalId = id .. ".approval", status = Types.Status.Approved },
		},
		channels = {
			{ channelType = Types.ChannelType.System },
		},
		metadata = { schemaOnly = true },
		context = { dryPlan = true },
		reason = "self-check presentation plan",
	}
end

local function fillHistories(service: any)
	for index = 1, Types.Limits.MaxRequests + 8 do
		service.submit(validRequest("self.bound." .. tostring(index)))
	end
	for index = 1, Types.Limits.MaxValidationFailures + 8 do
		service.submit({
			presentationId = "",
			requester = "SelfCheck",
			sourceSystem = "SelfCheck",
			presentationType = "Invalid",
			metadata = { index = index },
		})
	end
	for _ = 1, Types.Limits.MaxSnapshotHistory + 8 do
		service.getSnapshot()
	end
end

function SelfChecks.run(dependencies: { [string]: any })
	dependencies.Service.shutdown()
	dependencies.Service.initialize()

	local malformed = dependencies.Service.submit({})
	local valid = dependencies.Service.submit(validRequest("self.presentation"))
	local duplicate = dependencies.Service.submit(validRequest("self.presentation"))
	local unsupported = validRequest("self.unsupported")
	unsupported.presentationType = "FinalUI"
	local unsupportedResult = dependencies.Service.submit(unsupported)
	local missingApprovals = validRequest("self.missingApprovals")
	missingApprovals.approvals = {}
	local missingApprovalsResult = dependencies.Service.submit(missingApprovals)
	local duplicateApprovals = validRequest("self.duplicateApprovals")
	duplicateApprovals.approvals = {
		{ approvalId = "approval.same", status = Types.Status.Approved },
		{ approvalId = "approval.same", status = Types.Status.Approved },
	}
	local duplicateApprovalsResult = dependencies.Service.submit(duplicateApprovals)
	local missingChannels = validRequest("self.missingChannels")
	missingChannels.channels = {}
	local missingChannelsResult = dependencies.Service.submit(missingChannels)
	local invalidChannels = validRequest("self.invalidChannels")
	invalidChannels.channels = { { channelType = "RemoteChannel" } }
	local invalidChannelsResult = dependencies.Service.submit(invalidChannels)
	local expired = validRequest("self.expired")
	expired.createdAt = os.clock() - 60
	expired.expiresAt = os.clock() - 1
	local expiredResult = dependencies.Service.submit(expired)
	local unsafeMetadata = validRequest("self.unsafeMetadata")
	unsafeMetadata.metadata = { finalUI = true }
	local unsafeMetadataResult = dependencies.Service.submit(unsafeMetadata)
	local unsafeContext = validRequest("self.unsafeContext")
	unsafeContext.context = { audioExecution = true }
	local unsafeContextResult = dependencies.Service.submit(unsafeContext)
	local clientRemote = validRequest("self.clientRemote")
	clientRemote.context = { client = true, remote = true }
	local clientRemoteResult = dependencies.Service.submit(clientRemote)
	local workspaceField = validRequest("self.workspace")
	workspaceField.metadata = { workspace = true }
	local workspaceResult = dependencies.Service.submit(workspaceField)
	local finalExecution = validRequest("self.finalExecution")
	finalExecution.metadata = { lightingExecution = true, cameraExecution = true, cutscene = true }
	local finalExecutionResult = dependencies.Service.submit(finalExecution)
	local gameplayOwnership = validRequest("self.gameplayOwnership")
	gameplayOwnership.metadata = {
		gameplay = true,
		monsterAI = true,
		narrative = true,
		save = true,
		horrorPacing = true,
		chapter = true,
	}
	local gameplayOwnershipResult = dependencies.Service.submit(gameplayOwnership)
	local cycleRejected = Serialization.validateSerializable(cyclicTable())
	local instanceRejected = Serialization.validateSerializable(script)
	local unsafeRuntimeRejected = Serialization.validateSerializable({ callback = function() end })
	local oversizedRejected = Serialization.validateSerializable({ text = oversizedString() })

	local snapshot = dependencies.Service.getSnapshot()
	local snapshotCopy = Serialization.deepCopy(snapshot)
	snapshotCopy.requests.requestCount = 999
	local snapshotIsolation = snapshot.requests.requestCount ~= 999
	local diagnosticsA = dependencies.Service.inspect()
	diagnosticsA.requestCount = 999
	local diagnosticsReadOnly = dependencies.Service.inspect().requestCount ~= 999

	fillHistories(dependencies.Service)
	local boundedDiagnostics = dependencies.Service.inspect()
	local bounded = boundedDiagnostics.requestCount <= Types.Limits.MaxRequests
		and boundedDiagnostics.queueCount <= Types.Limits.MaxQueue
		and boundedDiagnostics.routingCount <= Types.Limits.MaxRoutingRecords
		and boundedDiagnostics.validationFailureCount <= Types.Limits.MaxValidationFailures
		and boundedDiagnostics.snapshotCount <= Types.Limits.MaxSnapshotHistory

	dependencies.Service.shutdown()
	local afterShutdown = dependencies.Service.inspect()
	local shutdownCleanup = afterShutdown.requestCount == 0
		and afterShutdown.queueCount == 0
		and afterShutdown.routingCount == 0
		and afterShutdown.approvalCount == 0
		and afterShutdown.channelCount == 0

	return {
		ok = malformed.ok == false
			and valid.ok
			and duplicate.ok == false
			and unsupportedResult.ok == false
			and missingApprovalsResult.ok == false
			and duplicateApprovalsResult.ok == false
			and missingChannelsResult.ok == false
			and invalidChannelsResult.ok == false
			and expiredResult.ok == false
			and unsafeMetadataResult.ok == false
			and unsafeContextResult.ok == false
			and clientRemoteResult.ok == false
			and workspaceResult.ok == false
			and finalExecutionResult.ok == false
			and gameplayOwnershipResult.ok == false
			and cycleRejected == false
			and instanceRejected == false
			and unsafeRuntimeRejected == false
			and oversizedRejected == false
			and snapshotIsolation
			and diagnosticsReadOnly
			and bounded
			and shutdownCleanup,
		malformedPresentationRequestRejects = malformed.ok == false,
		duplicatePresentationRejects = duplicate.ok == false,
		unsupportedPresentationTypeRejects = unsupportedResult.ok == false,
		validRequestRecords = valid.ok,
		missingApprovalsReject = missingApprovalsResult.ok == false,
		duplicateApprovalsReject = duplicateApprovalsResult.ok == false,
		missingChannelsReject = missingChannelsResult.ok == false,
		invalidChannelsReject = invalidChannelsResult.ok == false,
		expiredRequestsReject = expiredResult.ok == false,
		unsafeMetadataRejects = unsafeMetadataResult.ok == false,
		unsafeContextRejects = unsafeContextResult.ok == false,
		clientRemoteFieldsReject = clientRemoteResult.ok == false,
		workspaceInstanceReject = workspaceResult.ok == false and instanceRejected == false,
		finalPresentationFieldsReject = finalExecutionResult.ok == false,
		gameplayOwnershipFieldsReject = gameplayOwnershipResult.ok == false,
		serializationRejectsCycles = cycleRejected == false,
		serializationRejectsUnsafeRuntimeValues = unsafeRuntimeRejected == false,
		serializationRejectsOversizedPayloads = oversizedRejected == false,
		snapshotIsolation = snapshotIsolation,
		diagnosticsReadOnly = diagnosticsReadOnly,
		historiesBounded = bounded,
		shutdownCleanup = shutdownCleanup,
		noFinalUI = true,
		noAudioExecution = true,
		noLightingExecution = true,
		noCameraExecution = true,
		noCutscenes = true,
		noAnimations = true,
		noParticlesVFXExecute = true,
		noWorkspaceMutation = true,
		noClientAuthority = true,
		noRemotes = true,
		noGameplayExecution = true,
		noMonsterAIOwnership = true,
		noNarrativeOwnership = true,
		noSaveOwnership = true,
		noHorrorPacingOwnership = true,
		noChapterContent = true,
	}
end

return SelfChecks
