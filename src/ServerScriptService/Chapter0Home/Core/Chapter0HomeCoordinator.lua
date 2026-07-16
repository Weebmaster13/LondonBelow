--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local FeedbackService = require(ServerScriptService.Gameplay.Interaction.FeedbackService)
local ObservationSignals = require(ServerScriptService.Horror.Observation.ObservationSignals)
local Config = require(script.Parent.Chapter0HomeConfig)
local ChapterDiagnostics = require(script.Parent.Chapter0HomeDiagnostics)
local SelfChecks = require(script.Parent.Chapter0HomeSelfChecks)
local Serialization = require(script.Parent.Chapter0HomeSerialization)
local Signals = require(script.Parent.Chapter0HomeSignals)
local Snapshots = require(script.Parent.Chapter0HomeSnapshots)
local State = require(script.Parent.Chapter0HomeState)
local Types = require(script.Parent.Chapter0HomeTypes)
local Validation = require(script.Parent.Chapter0HomeValidation)

local Chapter0HomeCoordinator = {}

local log = Logger.scope("Chapter0Home")
local initialized = false
local started = false
local lastSelfChecks: any = nil
local worldConnections: { RBXScriptConnection } = {}
local lifecycleConnections: { RBXScriptConnection } = {}

local dependencies = {
	State = State,
	Validation = Validation,
}

local function feedbackForInteraction(interactionId: string): Types.AtmosphericFeedbackDefinition?
	for _, feedbackDefinition in ipairs(Config.Definition.atmosphericFeedback) do
		if feedbackDefinition.interactionId == interactionId then
			return feedbackDefinition
		end
	end

	return nil
end

local function reactionForInteraction(interactionId: string): Types.EnvironmentalReactionDefinition?
	for _, reactionDefinition in ipairs(Config.Definition.environmentalReactions) do
		if reactionDefinition.interactionId == interactionId then
			return reactionDefinition
		end
	end

	return nil
end

local function progressionTransitionForInteraction(
	interactionId: string
): Types.AtmosphericProgressionTransitionDefinition?
	for _, transitionDefinition in ipairs(Config.Definition.atmosphericProgressionTransitions) do
		if transitionDefinition.interactionId == interactionId then
			return transitionDefinition
		end
	end

	return nil
end

local function observationFactsForInteraction(
	interactionId: string
): { Types.ObservationFactDefinition }
	local facts = {}

	for _, factDefinition in ipairs(Config.Definition.observationFacts) do
		if factDefinition.interactionId == interactionId then
			table.insert(facts, factDefinition)
		end
	end

	return facts
end

local function instructionFromDefinition(feedbackDefinition: Types.AtmosphericFeedbackDefinition)
	return {
		kind = feedbackDefinition.kind,
		id = feedbackDefinition.instructionId,
		intensity = feedbackDefinition.intensity,
		duration = feedbackDefinition.duration,
		metadata = Serialization.deepCopy(feedbackDefinition.metadata),
	}
end

local function sendAtmosphericFeedback(userId: number, interactionId: string)
	local player = Players:GetPlayerByUserId(userId)
	local feedbackDefinition = feedbackForInteraction(interactionId)

	if player == nil or feedbackDefinition == nil then
		return
	end

	local recorded = State.recordAtmosphericFeedback(userId, {
		feedbackId = feedbackDefinition.feedbackId,
		interactionId = feedbackDefinition.interactionId,
		kind = feedbackDefinition.kind,
		instructionId = feedbackDefinition.instructionId,
		order = feedbackDefinition.order,
		metadata = Serialization.deepCopy(feedbackDefinition.metadata),
	})

	if not recorded then
		return
	end

	FeedbackService.send(player, { instructionFromDefinition(feedbackDefinition) })

	EventBus.publishDeferred(Signals.AtmosphericFeedbackRecorded, {
		chapterId = Types.ChapterId,
		userId = userId,
		interactionId = interactionId,
		feedbackId = feedbackDefinition.feedbackId,
	})
end

local function isOwnedRoot(instance: Instance): boolean
	return instance.Name == Types.RootFolderName
		and instance:GetAttribute("ChapterId") == Types.ChapterId
		and instance:GetAttribute("OwnerRuntime") == Types.RuntimeName
end

local function collectRootState()
	local ownedRoots = {}
	local foreignRootCount = 0

	for _, child in ipairs(Workspace:GetChildren()) do
		if child.Name == Types.RootFolderName then
			if isOwnedRoot(child) then
				table.insert(ownedRoots, child)
			else
				foreignRootCount += 1
			end
		end
	end

	return ownedRoots, foreignRootCount
end

local function findReactionTarget(
	reactionDefinition: Types.EnvironmentalReactionDefinition
): Instance?
	local ownedRoots = collectRootState()
	local root = ownedRoots[1]

	if root == nil then
		return nil
	end

	if reactionDefinition.targetKind == Types.EnvironmentalReactionTargetKind.ChapterRoot then
		return root
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if
			reactionDefinition.targetKind == Types.EnvironmentalReactionTargetKind.Room
			and descendant:GetAttribute("RoomId") == reactionDefinition.targetId
		then
			return descendant
		end

		if
			reactionDefinition.targetKind == Types.EnvironmentalReactionTargetKind.Interaction
			and descendant:GetAttribute("InteractionId") == reactionDefinition.targetId
		then
			return descendant
		end
	end

	return nil
end

local function applyEnvironmentalReaction(userId: number, interactionId: string)
	local reactionDefinition = reactionForInteraction(interactionId)

	if reactionDefinition == nil then
		return
	end

	local target = findReactionTarget(reactionDefinition)

	if target == nil then
		return
	end

	local recorded = State.recordEnvironmentalReaction(userId, {
		reactionId = reactionDefinition.reactionId,
		interactionId = reactionDefinition.interactionId,
		kind = reactionDefinition.kind,
		targetKind = reactionDefinition.targetKind,
		targetId = reactionDefinition.targetId,
		order = reactionDefinition.order,
		intensity = reactionDefinition.intensity,
		metadata = Serialization.deepCopy(reactionDefinition.metadata),
	})

	if not recorded then
		return
	end

	target:SetAttribute(
		Types.EnvironmentalReactionAttributeNames.ReactionId,
		reactionDefinition.reactionId
	)
	target:SetAttribute(
		Types.EnvironmentalReactionAttributeNames.InteractionId,
		reactionDefinition.interactionId
	)
	target:SetAttribute(Types.EnvironmentalReactionAttributeNames.Kind, reactionDefinition.kind)
	target:SetAttribute(
		Types.EnvironmentalReactionAttributeNames.TargetKind,
		reactionDefinition.targetKind
	)
	target:SetAttribute(
		Types.EnvironmentalReactionAttributeNames.TargetId,
		reactionDefinition.targetId
	)
	target:SetAttribute(
		Types.EnvironmentalReactionAttributeNames.Intensity,
		reactionDefinition.intensity
	)
	target:SetAttribute(Types.EnvironmentalReactionAttributeNames.Order, reactionDefinition.order)

	for key, value in pairs(reactionDefinition.metadata) do
		if type(value) == "string" or type(value) == "number" or type(value) == "boolean" then
			target:SetAttribute(Types.EnvironmentalReactionAttributePrefix .. key, value)
		end
	end

	EventBus.publishDeferred(Signals.EnvironmentalReactionApplied, {
		chapterId = Types.ChapterId,
		userId = userId,
		interactionId = interactionId,
		reactionId = reactionDefinition.reactionId,
	})
end

local function applyAtmosphericProgression(userId: number, interactionId: string)
	local transitionDefinition = progressionTransitionForInteraction(interactionId)

	if transitionDefinition == nil then
		return
	end

	local snapshot = State.snapshot()
	local progress = snapshot.playerProgress[userId]

	if progress == nil then
		return
	end

	if progress.progressionStageId ~= transitionDefinition.fromStageId then
		return
	end

	for _, requiredId in ipairs(transitionDefinition.requiredInteractionIds) do
		if progress.interactions[requiredId] ~= true then
			return
		end
	end

	local recorded = State.recordAtmosphericProgression(userId, {
		transitionId = transitionDefinition.transitionId,
		interactionId = transitionDefinition.interactionId,
		fromStageId = transitionDefinition.fromStageId,
		toStageId = transitionDefinition.toStageId,
		order = transitionDefinition.order,
		requiredInteractionIds = Serialization.deepCopy(
			transitionDefinition.requiredInteractionIds
		),
		feedbackId = transitionDefinition.feedbackId,
		reactionId = transitionDefinition.reactionId,
		optionalModifier = transitionDefinition.optionalModifier,
		completionRelevant = transitionDefinition.completionRelevant,
		intensity = transitionDefinition.intensity,
		metadata = Serialization.deepCopy(transitionDefinition.metadata),
	})

	if not recorded then
		return
	end

	EventBus.publishDeferred(Signals.AtmosphericProgressionAdvanced, {
		chapterId = Types.ChapterId,
		userId = userId,
		interactionId = interactionId,
		transitionId = transitionDefinition.transitionId,
		stageId = transitionDefinition.toStageId,
		optionalModifier = transitionDefinition.optionalModifier,
	})
end

local function publishChapterObservationFacts(userId: number, interactionId: string)
	local player = Players:GetPlayerByUserId(userId)
	local facts = observationFactsForInteraction(interactionId)

	for _, factDefinition in ipairs(facts) do
		local snapshot = State.snapshot()
		local progress = snapshot.playerProgress[userId]

		if progress == nil or progress.interactions[factDefinition.interactionId] ~= true then
			continue
		end

		if
			factDefinition.optionalModifier ~= true
			and progress.progressionStageId ~= factDefinition.stageId
		then
			continue
		end

		local recorded = State.recordObservationFact(userId, {
			factId = factDefinition.factId,
			observationId = factDefinition.observationId,
			chapterId = factDefinition.chapterId,
			sourceRuntime = factDefinition.sourceRuntime,
			contractVersion = factDefinition.contractVersion,
			authority = factDefinition.authority,
			kind = factDefinition.kind,
			interactionId = factDefinition.interactionId,
			stageId = factDefinition.stageId,
			feedbackId = factDefinition.feedbackId,
			reactionId = factDefinition.reactionId,
			order = factDefinition.order,
			intensity = factDefinition.intensity,
			completionRelevant = factDefinition.completionRelevant,
			optionalModifier = factDefinition.optionalModifier,
			metadata = Serialization.deepCopy(factDefinition.metadata),
		})

		if recorded then
			EventBus.publishDeferred(Signals.ObservationFactPublished, {
				chapterId = Types.ChapterId,
				userId = userId,
				factId = factDefinition.factId,
				observationId = factDefinition.observationId,
				interactionId = factDefinition.interactionId,
				stageId = factDefinition.stageId,
			})

			EventBus.publishDeferred(ObservationSignals.Submitted, {
				id = factDefinition.observationId,
				player = player,
				amount = factDefinition.intensity,
				source = Types.ObservationSourceRuntime,
				metadata = {
					factId = factDefinition.factId,
					chapterId = factDefinition.chapterId,
					sourceRuntime = factDefinition.sourceRuntime,
					contractVersion = factDefinition.contractVersion,
					authority = factDefinition.authority,
					observationKind = factDefinition.kind,
					interactionId = factDefinition.interactionId,
					stageId = factDefinition.stageId,
					feedbackId = factDefinition.feedbackId,
					reactionId = factDefinition.reactionId,
					order = factDefinition.order,
					intensity = factDefinition.intensity,
					completionRelevant = factDefinition.completionRelevant,
					optionalModifier = factDefinition.optionalModifier,
					metadata = Serialization.deepCopy(factDefinition.metadata),
				},
			})
		end
	end
end

local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.Color = color
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function addWall(parent: Instance, name: string, size: Vector3, position: Vector3)
	local wall = makePart(parent, name, size, position, Color3.fromRGB(82, 73, 66))
	wall.Material = Enum.Material.Brick
	return wall
end

local function createRoom(root: Folder, room: Types.RoomDefinition)
	local folder = Instance.new("Folder")
	folder.Name = room.roomId
	folder:SetAttribute("ChapterId", Types.ChapterId)
	folder:SetAttribute("RoomId", room.roomId)
	folder:SetAttribute("RoomKind", room.kind)
	folder.Parent = root

	local floor = makePart(folder, "Floor", room.size, room.position, Color3.fromRGB(74, 62, 52))
	floor.Material = Enum.Material.WoodPlanks

	local halfX = room.size.X / 2
	local halfZ = room.size.Z / 2
	addWall(
		folder,
		"NorthWall",
		Vector3.new(room.size.X, 8, 1),
		room.position + Vector3.new(0, 4, -halfZ)
	)
	addWall(
		folder,
		"SouthWall",
		Vector3.new(room.size.X, 8, 1),
		room.position + Vector3.new(0, 4, halfZ)
	)
	addWall(
		folder,
		"WestWall",
		Vector3.new(1, 8, room.size.Z),
		room.position + Vector3.new(-halfX, 4, 0)
	)
	addWall(
		folder,
		"EastWall",
		Vector3.new(1, 8, room.size.Z),
		room.position + Vector3.new(halfX, 4, 0)
	)

	return folder
end

local function createSpawn(root: Folder)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Chapter0HomeStart"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = Config.Definition.spawnPosition
	spawn.Transparency = 0.35
	spawn.Color = Color3.fromRGB(96, 117, 102)
	spawn:SetAttribute("ChapterId", Types.ChapterId)
	spawn:SetAttribute("StartState", true)
	spawn.Parent = root
	return spawn
end

local function createInteraction(root: Folder, interaction: Types.InteractionDefinition)
	local part = makePart(
		root,
		interaction.interactionId,
		interaction.size,
		interaction.position,
		Color3.fromRGB(124, 102, 77)
	)
	part:SetAttribute("ChapterId", Types.ChapterId)
	part:SetAttribute("RoomId", interaction.roomId)
	part:SetAttribute("InteractionId", interaction.interactionId)
	part:SetAttribute("InteractionKind", interaction.kind)
	part:SetAttribute("Prompt", interaction.prompt)
	part:SetAttribute("MaxDistance", 12)
	part:SetAttribute("RequiresLineOfSight", false)
	part:SetAttribute("Replayable", interaction.kind ~= Types.InteractionKind.Collectible)
	part:SetAttribute("InteractionEnabled", true)
	part:SetAttribute("RequiredForCompletion", interaction.requiredForCompletion)

	for key, value in pairs(interaction.metadata) do
		part:SetAttribute("Meta_" .. key, value)
	end

	if not CollectionService:HasTag(part, "LondonInteractable") then
		CollectionService:AddTag(part, "LondonInteractable")
	end

	table.insert(
		worldConnections,
		part:GetAttributeChangedSignal("LastInteractedAt"):Connect(function()
			local userId = part:GetAttribute("LastInteractedByUserId")

			if type(userId) ~= "number" then
				return
			end

			local completed = State.recordInteraction(
				userId,
				interaction.interactionId,
				Config.Definition.completionInteractionIds
			)

			EventBus.publishDeferred(Signals.InteractionRecorded, {
				chapterId = Types.ChapterId,
				userId = userId,
				interactionId = interaction.interactionId,
			})

			sendAtmosphericFeedback(userId, interaction.interactionId)
			applyEnvironmentalReaction(userId, interaction.interactionId)
			applyAtmosphericProgression(userId, interaction.interactionId)
			publishChapterObservationFacts(userId, interaction.interactionId)

			if completed then
				EventBus.publishDeferred(Signals.Completed, {
					chapterId = Types.ChapterId,
					userId = userId,
				})
			end
		end)
	)

	return part
end

local function destroyOwnedRoot()
	for _, connection in ipairs(worldConnections) do
		connection:Disconnect()
	end

	table.clear(worldConnections)

	local ownedRoots = collectRootState()

	for _, root in ipairs(ownedRoots) do
		root:Destroy()
	end
end

function Chapter0HomeCoordinator.reset()
	destroyOwnedRoot()
	local _, foreignRootCount = collectRootState()

	if foreignRootCount > 0 then
		error(
			"Cannot reset Chapter 0 Home while unowned Workspace."
				.. Types.RootFolderName
				.. " exists",
			0
		)
	end

	State.clear()
	State.setStatus(Types.PhaseStatus.Started)

	local root = Instance.new("Folder")
	root.Name = Types.RootFolderName
	root:SetAttribute("ChapterId", Types.ChapterId)
	root:SetAttribute("OwnerRuntime", Types.RuntimeName)
	root.Parent = Workspace

	createSpawn(root)

	local roomsFolder = Instance.new("Folder")
	roomsFolder.Name = "Rooms"
	roomsFolder.Parent = root

	for _, room in ipairs(Config.Definition.rooms) do
		createRoom(roomsFolder, room)
	end

	local interactionsFolder = Instance.new("Folder")
	interactionsFolder.Name = "Interactables"
	interactionsFolder.Parent = root

	for _, interaction in ipairs(Config.Definition.interactions) do
		createInteraction(interactionsFolder, interaction)
	end

	EventBus.publishDeferred(Signals.Reset, {
		chapterId = Types.ChapterId,
	})
end

function Chapter0HomeCoordinator.initialize()
	if initialized then
		return
	end

	local valid, reason = Chapter0HomeCoordinator.validate()

	if not valid then
		error("Chapter0HomeCoordinator validation failed: " .. tostring(reason), 0)
	end

	Diagnostics.registerSampler(Types.ProviderName, Chapter0HomeCoordinator.inspect)
	SnapshotManager.registerProvider(
		Types.SnapshotProviderName,
		Chapter0HomeCoordinator.getSnapshot
	)
	initialized = true
	log.success("Chapter 0 Home initialized")
end

function Chapter0HomeCoordinator.start()
	if started then
		return
	end

	if not initialized then
		Chapter0HomeCoordinator.initialize()
	end

	Chapter0HomeCoordinator.reset()

	table.insert(
		lifecycleConnections,
		Players.PlayerRemoving:Connect(function(player)
			State.removePlayer(player.UserId)
		end)
	)

	State.setStatus(Types.PhaseStatus.Started)
	EventBus.publishDeferred(Signals.Started, {
		chapterId = Types.ChapterId,
	})
	started = true
end

function Chapter0HomeCoordinator.shutdown()
	destroyOwnedRoot()

	for _, connection in ipairs(lifecycleConnections) do
		connection:Disconnect()
	end

	table.clear(lifecycleConnections)
	State.clear()
	started = false
	initialized = false
end

function Chapter0HomeCoordinator.inspect()
	local ownedRoots, foreignRootCount = collectRootState()

	return ChapterDiagnostics.capture({
		initialized = initialized,
		started = started,
		lastSelfChecks = lastSelfChecks,
		worldConnectionCount = #worldConnections,
		lifecycleConnectionCount = #lifecycleConnections,
		ownedRootCount = #ownedRoots,
		foreignRootCount = foreignRootCount,
	}, Config.Definition, State)
end

function Chapter0HomeCoordinator.getSnapshot()
	return Snapshots.capture(State, Config.Definition)
end

function Chapter0HomeCoordinator.validate(): (boolean, string?)
	local depsOk, depsReason = ChapterDiagnostics.validate(dependencies)

	if not depsOk then
		return false, depsReason
	end

	local definitionOk, definitionReason = Validation.validateDefinition(Config.Definition)

	if not definitionOk then
		State.recordValidationFailure(definitionReason or "definition invalid", Config.Definition)
		return false, definitionReason
	end

	return true, nil
end

function Chapter0HomeCoordinator.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "Chapter 0 Home self-checks are destructive and may only run before start.",
		}
		return lastSelfChecks
	end

	lastSelfChecks = SelfChecks.run({ Service = Chapter0HomeCoordinator })
	return Serialization.deepCopy(lastSelfChecks)
end

return Chapter0HomeCoordinator
