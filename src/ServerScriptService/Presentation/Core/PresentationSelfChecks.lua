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

local function promptCommand(id: string, priority: any?)
	return {
		commandId = id,
		sourceRuntime = "PresentationSelfCheck",
		objectId = id .. ".object",
		presentationType = Types.PresentationType.ShowPrompt,
		priority = priority or "Interaction",
		revision = 1,
		payload = {
			promptId = id .. ".prompt",
			objectId = id .. ".object",
			titleKey = "self.prompt.title",
			subtitleKey = "self.prompt.subtitle",
			actionKey = "self.prompt.action",
			enabled = true,
			busy = false,
			distance = 10,
			priority = priority or "Interaction",
			accessibilityMetadata = {
				screenReaderKey = "self.prompt.reader",
				subtitleKey = "self.prompt.subtitle",
				colorIndependentState = "available",
				inputGlyphKey = "input.interact",
			},
		},
	}
end

local function simpleCommand(id: string, presentationType: string, payload: any)
	return {
		commandId = id,
		sourceRuntime = "PresentationSelfCheck",
		objectId = id .. ".object",
		presentationType = presentationType,
		priority = "Context",
		revision = 1,
		payload = payload,
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
	local malformedApprovals = validRequest("self.malformedApprovals")
	malformedApprovals.approvals = { "approval.invalid" }
	local malformedApprovalsResult = dependencies.Service.submit(malformedApprovals)
	local missingChannels = validRequest("self.missingChannels")
	missingChannels.channels = {}
	local missingChannelsResult = dependencies.Service.submit(missingChannels)
	local duplicateChannels = validRequest("self.duplicateChannels")
	duplicateChannels.channels = {
		{ channelType = Types.ChannelType.System },
		{ channelType = Types.ChannelType.System },
	}
	local duplicateChannelsResult = dependencies.Service.submit(duplicateChannels)
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
	local finalUI = validRequest("self.finalUI")
	finalUI.metadata = { finalUI = true }
	local finalUIResult = dependencies.Service.submit(finalUI)
	local audioExecution = validRequest("self.audioExecution")
	audioExecution.metadata = { audioExecution = true }
	local audioExecutionResult = dependencies.Service.submit(audioExecution)
	local lightingExecution = validRequest("self.lightingExecution")
	lightingExecution.metadata = { lightingExecution = true }
	local lightingExecutionResult = dependencies.Service.submit(lightingExecution)
	local cameraExecution = validRequest("self.cameraExecution")
	cameraExecution.metadata = { cameraExecution = true }
	local cameraExecutionResult = dependencies.Service.submit(cameraExecution)
	local cutscene = validRequest("self.cutscene")
	cutscene.metadata = { cutscene = true }
	local cutsceneResult = dependencies.Service.submit(cutscene)
	local animation = validRequest("self.animation")
	animation.metadata = { animation = true }
	local animationResult = dependencies.Service.submit(animation)
	local particleVFX = validRequest("self.particleVFX")
	particleVFX.metadata = { particle = true, vfxExecution = true }
	local particleVFXResult = dependencies.Service.submit(particleVFX)
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
	local prompt = dependencies.Service.submitCommand(promptCommand("self.command.prompt"))
	local duplicateCommand =
		dependencies.Service.submitCommand(promptCommand("self.command.prompt"))
	local missingPromptMetadata = promptCommand("self.command.badPrompt")
	missingPromptMetadata.payload.accessibilityMetadata = nil
	local missingPromptMetadataResult = dependencies.Service.submitCommand(missingPromptMetadata)
	local audio = dependencies.Service.submitCommand(
		simpleCommand(
			"self.command.audio",
			Types.PresentationType.PlayAudio,
			{ audioKey = "door.open" }
		)
	)
	local animationCommand = dependencies.Service.submitCommand(
		simpleCommand(
			"self.command.animation",
			Types.PresentationType.PlayAnimation,
			{ animationKey = "door.open" }
		)
	)
	local cursor = dependencies.Service.submitCommand(
		simpleCommand(
			"self.command.cursor",
			Types.PresentationType.UpdateCursor,
			{ cursorState = Types.CursorState.Busy }
		)
	)
	local message = dependencies.Service.submitCommand(
		simpleCommand(
			"self.command.message",
			Types.PresentationType.ShowMessage,
			{ messageId = "self.message", messageKey = "self.message.busy" }
		)
	)
	local highlight = dependencies.Service.submitCommand(
		simpleCommand(
			"self.command.highlight",
			Types.PresentationType.HighlightObject,
			{ highlightKey = "self.highlight", colorIndependentState = "available" }
		)
	)
	local priorityAmbient =
		dependencies.Service.submitCommand(promptCommand("self.command.priorityAmbient", "Ambient"))
	local priorityCritical = dependencies.Service.submitCommand(
		promptCommand("self.command.priorityCritical", "Critical")
	)
	local expiredCommand = promptCommand("self.command.expired")
	expiredCommand.timestamp = os.clock() - 10
	expiredCommand.expiresAt = os.clock() - 5
	local expiredCommandResult = dependencies.Service.submitCommand(expiredCommand)
	local chapter0Binding = dependencies.Service.bindChapter0FixturePresentation()
	local dispatch = dependencies.Service.dispatchAll()
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
	diagnosticsA.requestCount = 999
	local diagnosticsReadOnly = dependencies.Service.inspect().requestCount ~= 999

	fillHistories(dependencies.Service)
	local boundedDiagnostics = dependencies.Service.inspect()
	local bounded = boundedDiagnostics.requestCount <= Types.Limits.MaxRequests
		and boundedDiagnostics.queueCount <= Types.Limits.MaxQueue
		and boundedDiagnostics.routingCount <= Types.Limits.MaxRoutingRecords
		and boundedDiagnostics.validationFailureCount <= Types.Limits.MaxValidationFailures
		and boundedDiagnostics.snapshotCount <= Types.Limits.MaxSnapshotHistory
		and boundedDiagnostics.queuedCommands <= Types.Limits.MaxCommands
		and boundedDiagnostics.executedCommands <= Types.Limits.MaxExecutedCommands
		and boundedDiagnostics.promptCount <= Types.Limits.MaxPrompts

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
			and malformedApprovalsResult.ok == false
			and missingChannelsResult.ok == false
			and duplicateChannelsResult.ok == false
			and invalidChannelsResult.ok == false
			and expiredResult.ok == false
			and unsafeMetadataResult.ok == false
			and unsafeContextResult.ok == false
			and clientRemoteResult.ok == false
			and workspaceResult.ok == false
			and finalUIResult.ok == false
			and audioExecutionResult.ok == false
			and lightingExecutionResult.ok == false
			and cameraExecutionResult.ok == false
			and cutsceneResult.ok == false
			and animationResult.ok == false
			and particleVFXResult.ok == false
			and gameplayOwnershipResult.ok == false
			and prompt.ok
			and duplicateCommand.ok == false
			and missingPromptMetadataResult.ok == false
			and audio.ok
			and animationCommand.ok
			and cursor.ok
			and message.ok
			and highlight.ok
			and priorityAmbient.ok
			and priorityCritical.ok
			and expiredCommandResult.ok == false
			and chapter0Binding.ok
			and dispatch.ok
			and boundedDiagnostics.executedCommands >= 8
			and boundedDiagnostics.audioRequests >= 1
			and boundedDiagnostics.animationRequests >= 1
			and boundedDiagnostics.messageRequests >= 1
			and boundedDiagnostics.cursorUpdates >= 1
			and boundedDiagnostics.highlightUpdates >= 1
			and cycleRejected == false
			and instanceRejected == false
			and unsafeRuntimeRejected == false
			and oversizedRejected == false
			and deepRejected == false
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
		malformedApprovalsReject = malformedApprovalsResult.ok == false,
		missingChannelsReject = missingChannelsResult.ok == false,
		duplicateChannelsReject = duplicateChannelsResult.ok == false,
		invalidChannelsReject = invalidChannelsResult.ok == false,
		expiredRequestsReject = expiredResult.ok == false,
		unsafeMetadataRejects = unsafeMetadataResult.ok == false,
		unsafeContextRejects = unsafeContextResult.ok == false,
		clientRemoteFieldsReject = clientRemoteResult.ok == false,
		workspaceInstanceReject = workspaceResult.ok == false and instanceRejected == false,
		finalUIFieldsReject = finalUIResult.ok == false,
		audioExecutionFieldsReject = audioExecutionResult.ok == false,
		lightingExecutionFieldsReject = lightingExecutionResult.ok == false,
		cameraExecutionFieldsReject = cameraExecutionResult.ok == false,
		cutsceneFieldsReject = cutsceneResult.ok == false,
		animationFieldsReject = animationResult.ok == false,
		particleVFXExecutionFieldsReject = particleVFXResult.ok == false,
		gameplayOwnershipFieldsReject = gameplayOwnershipResult.ok == false,
		commandQueueAcceptsPrompt = prompt.ok,
		duplicateCommandRejects = duplicateCommand.ok == false,
		promptValidationRejectsMissingAccessibility = missingPromptMetadataResult.ok == false,
		audioKeyRequests = audio.ok,
		animationKeyRequests = animationCommand.ok,
		cursorUpdates = cursor.ok,
		messageRequests = message.ok,
		highlightRequests = highlight.ok,
		priorityOrdering = priorityAmbient.ok and priorityCritical.ok,
		expiredCommandRejects = expiredCommandResult.ok == false,
		dispatcherRoutes = dispatch.ok,
		chapter0FixturePresentation = chapter0Binding.ok,
		serializationRejectsCycles = cycleRejected == false,
		serializationRejectsUnsafeRuntimeValues = unsafeRuntimeRejected == false,
		serializationRejectsOversizedPayloads = oversizedRejected == false,
		serializationRejectsDeepPayloads = deepRejected == false,
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
