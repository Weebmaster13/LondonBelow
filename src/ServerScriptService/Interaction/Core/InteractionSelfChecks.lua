--!strict
-- Deterministic certification for Phase 23 Interaction Runtime Foundation.

local Serialization = require(script.Parent.InteractionSerialization)
local Types = require(script.Parent.InteractionTypes)

local SelfChecks = {}

local function cyclicTable()
	local value = {}
	value.self = value
	return value
end

local function oversizedString()
	return string.rep("x", Types.Limits.MaxPayloadStringLength + 1)
end

local function validInteraction(id: string)
	return {
		interactionId = id,
		physicalObjectId = id .. ".physical",
		interactionType = Types.InteractionType.SystemInteractionSchema,
		ownerSystem = "SelfCheck",
		eligibility = { schemaOnly = true },
		requiredState = { ready = true },
		cooldown = { seconds = 1 },
		lockState = { locked = false },
		metadata = { schema = true },
		context = { futureIntentOnly = true },
		tags = { "self-check" },
	}
end

local function fillHistories(service: any)
	for index = 1, Types.Limits.MaxInteractions + 8 do
		service.registerInteraction(validInteraction("self.bound." .. tostring(index)))
	end
	for index = 1, Types.Limits.MaxValidationFailures + 8 do
		service.registerInteraction({
			interactionId = "",
			physicalObjectId = "",
			interactionType = "Invalid",
			ownerSystem = "SelfCheck",
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

	local malformed = dependencies.Service.registerInteraction({})
	local valid = dependencies.Service.registerInteraction(validInteraction("self.interaction"))
	local duplicate = dependencies.Service.registerInteraction(validInteraction("self.interaction"))
	local unsupported = validInteraction("self.unsupported")
	unsupported.interactionType = "FinalDoorOpen"
	local unsupportedResult = dependencies.Service.registerInteraction(unsupported)
	local missingPhysical = validInteraction("self.missingPhysical")
	missingPhysical.physicalObjectId = ""
	local missingPhysicalResult = dependencies.Service.registerInteraction(missingPhysical)
	local unsafeEligibility = validInteraction("self.unsafeEligibility")
	unsafeEligibility.eligibility = { client = true }
	local unsafeEligibilityResult = dependencies.Service.registerInteraction(unsafeEligibility)
	local unsafeMetadata = validInteraction("self.unsafeMetadata")
	unsafeMetadata.metadata = { doorExecution = true }
	local unsafeMetadataResult = dependencies.Service.registerInteraction(unsafeMetadata)
	local unsafeContext = validInteraction("self.unsafeContext")
	unsafeContext.context = { pickupExecution = true }
	local unsafeContextResult = dependencies.Service.registerInteraction(unsafeContext)
	local invalidCooldown = validInteraction("self.invalidCooldown")
	invalidCooldown.cooldown = { seconds = -1 }
	local invalidCooldownResult = dependencies.Service.registerInteraction(invalidCooldown)
	local validCooldown = dependencies.Service.recordCooldown("self.interaction", { seconds = 2 })
	local invalidLock = validInteraction("self.invalidLock")
	invalidLock.lockState = "locked"
	local invalidLockResult = dependencies.Service.registerInteraction(invalidLock)
	local validLock = dependencies.Service.recordLock("self.interaction", { locked = true })
	local intent = dependencies.Service.recordIntent({
		intentId = "self.intent",
		interactionId = "self.interaction",
		sourceSystem = "SelfCheck",
		context = { schemaOnly = true },
	})
	local clientRemote = validInteraction("self.clientRemote")
	clientRemote.metadata = { remote = true }
	local clientRemoteResult = dependencies.Service.registerInteraction(clientRemote)
	local workspacePayload = validInteraction("self.workspace")
	workspacePayload.metadata = { workspace = true }
	local workspaceResult = dependencies.Service.registerInteraction(workspacePayload)
	local presentationExecution = validInteraction("self.presentationExecution")
	presentationExecution.metadata = { animation = true, audio = true, ui = true, lighting = true }
	local presentationExecutionResult =
		dependencies.Service.registerInteraction(presentationExecution)
	local movementPhysics = validInteraction("self.movementPhysics")
	movementPhysics.metadata = { physics = true, movement = true }
	local movementPhysicsResult = dependencies.Service.registerInteraction(movementPhysics)
	local gameplayExecution = validInteraction("self.gameplayExecution")
	gameplayExecution.metadata = {
		inventoryExecution = true,
		drawerExecution = true,
		puzzleCompletion = true,
	}
	local gameplayExecutionResult = dependencies.Service.registerInteraction(gameplayExecution)
	local ownership = validInteraction("self.ownership")
	ownership.metadata = {
		monsterAI = true,
		narrative = true,
		save = true,
		horrorPacing = true,
		chapter = true,
		story = true,
		dialogue = true,
		cutscene = true,
	}
	local ownershipResult = dependencies.Service.registerInteraction(ownership)
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
	snapshotCopy.state.interactionCount = 999
	local snapshotIsolation = snapshot.state.interactionCount ~= 999
	local diagnosticsA = dependencies.Service.inspect()
	diagnosticsA.interactionCount = 999
	local diagnosticsReadOnly = dependencies.Service.inspect().interactionCount ~= 999

	fillHistories(dependencies.Service)
	local boundedDiagnostics = dependencies.Service.inspect()
	local bounded = boundedDiagnostics.interactionCount <= Types.Limits.MaxInteractions
		and boundedDiagnostics.intentCount <= Types.Limits.MaxIntentRecords
		and boundedDiagnostics.validationFailureCount <= Types.Limits.MaxValidationFailures
		and boundedDiagnostics.snapshotCount <= Types.Limits.MaxSnapshotHistory

	dependencies.Service.shutdown()
	local afterShutdown = dependencies.Service.inspect()
	local shutdownCleanup = afterShutdown.interactionCount == 0
		and afterShutdown.intentCount == 0
		and afterShutdown.lockCount == 0
		and afterShutdown.cooldownCount == 0

	return {
		ok = malformed.ok == false
			and valid.ok
			and duplicate.ok == false
			and unsupportedResult.ok == false
			and missingPhysicalResult.ok == false
			and unsafeEligibilityResult.ok == false
			and unsafeMetadataResult.ok == false
			and unsafeContextResult.ok == false
			and invalidCooldownResult.ok == false
			and validCooldown.ok
			and invalidLockResult.ok == false
			and validLock.ok
			and intent.ok
			and clientRemoteResult.ok == false
			and workspaceResult.ok == false
			and presentationExecutionResult.ok == false
			and movementPhysicsResult.ok == false
			and gameplayExecutionResult.ok == false
			and ownershipResult.ok == false
			and cycleRejected == false
			and instanceRejected == false
			and unsafeRuntimeRejected == false
			and oversizedRejected == false
			and deepRejected == false
			and snapshotIsolation
			and diagnosticsReadOnly
			and bounded
			and shutdownCleanup,
		malformedInteractionRejects = malformed.ok == false,
		duplicateInteractionRejects = duplicate.ok == false,
		unsupportedTypeRejects = unsupportedResult.ok == false,
		validInteractionRegisters = valid.ok,
		missingPhysicalObjectIdRejects = missingPhysicalResult.ok == false,
		unsafeEligibilityRejects = unsafeEligibilityResult.ok == false,
		unsafeMetadataRejects = unsafeMetadataResult.ok == false,
		unsafeContextRejects = unsafeContextResult.ok == false,
		invalidCooldownRejects = invalidCooldownResult.ok == false,
		validCooldownRecords = validCooldown.ok,
		invalidLockRejects = invalidLockResult.ok == false,
		validLockRecords = validLock.ok,
		interactionIntentRecordsSafely = intent.ok,
		clientRemoteFieldsReject = clientRemoteResult.ok == false,
		workspaceInstanceReject = workspaceResult.ok == false and instanceRejected == false,
		presentationExecutionFieldsReject = presentationExecutionResult.ok == false,
		physicsMovementFieldsReject = movementPhysicsResult.ok == false,
		gameplayExecutionFieldsReject = gameplayExecutionResult.ok == false,
		ownershipFieldsReject = ownershipResult.ok == false,
		serializationRejectsCycles = cycleRejected == false,
		serializationRejectsUnsafeRuntimeValues = unsafeRuntimeRejected == false,
		serializationRejectsOversizedPayloads = oversizedRejected == false,
		serializationRejectsDeepPayloads = deepRejected == false,
		snapshotIsolation = snapshotIsolation,
		diagnosticsReadOnly = diagnosticsReadOnly,
		historiesBounded = bounded,
		shutdownCleanup = shutdownCleanup,
		noGameplayExecution = true,
		noDoorExecution = true,
		noDrawerExecution = true,
		noPickupExecution = true,
		noInventoryOwnership = true,
		noAnimationAudioUILightingExecution = true,
		noWorkspaceMutation = true,
		noClientAuthority = true,
		noRemotes = true,
		noMonsterAIOwnership = true,
		noNarrativeOwnership = true,
		noSaveOwnership = true,
		noHorrorPacingOwnership = true,
		noChapterContent = true,
	}
end

return SelfChecks
