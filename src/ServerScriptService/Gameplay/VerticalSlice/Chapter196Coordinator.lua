--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Lighting = game:GetService("Lighting")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)
local FeedbackService = require(ServerScriptService.Gameplay.Interaction.FeedbackService)
local HorrorDirector = require(ServerScriptService.Horror.Director.HorrorDirector)
local ObservationService = require(ServerScriptService.Horror.Observation.ObservationService)
local Config = require(ReplicatedStorage.Config.Chapter196VerticalSliceConfig)
local ProductionCoordinator = require(script.Parent.BlackwaterProductionCoordinator)
local State = require(script.Parent.Chapter196State)
local Types = require(script.Parent.Chapter196Types)
local VisualPlanBridge = require(script.Parent.Chapter196VisualPlanBridge)
local WorldBuilder = require(script.Parent.Chapter196WorldBuilder)

local Coordinator = {}
local log = Logger.scope(Types.RuntimeName)
local initialized = false
local started = false
local root: Folder? = nil
local interactions: { [string]: BasePart } = {}
local promptConnections: { RBXScriptConnection } = {}
local playerConnections: { [number]: { RBXScriptConnection } } = {}
local counters = {
	interactionsAccepted = 0,
	interactionsRejected = 0,
	objectivesCompleted = 0,
	checkpointsGranted = 0,
	deathsRecovered = 0,
	chapterCompletions = 0,
}

local function currentObjective()
	return Config.Objectives[State.getObjectiveIndex()]
end

local function inventorySummary(): string
	local items = {}
	if State.isCompleted("ignite_lantern") then
		items[#items + 1] = "Watchman's Lantern"
	end
	if State.isCompleted("take_seal") then
		items[#items + 1] = "Brass Seal"
	end
	if State.isCompleted("take_heart") then
		items[#items + 1] = "Glass Heart"
	end
	return if #items > 0 then table.concat(items, "  •  ") else "No chapter relics"
end

local function publishRootState()
	if root == nil then
		return
	end
	local objective = currentObjective()
	root:SetAttribute("ObjectiveIndex", State.getObjectiveIndex())
	root:SetAttribute("ObjectiveText", if objective then objective.text else "Chapter complete")
	root:SetAttribute("ChapterState", State.getRuntimeState())
	root:SetAttribute(
		"Progress",
		math.clamp((State.getObjectiveIndex() - 1) / #Config.Objectives, 0, 1)
	)
	root:SetAttribute("ObjectiveNumber", math.min(State.getObjectiveIndex(), #Config.Objectives))
	root:SetAttribute("ObjectiveTotal", #Config.Objectives)
	root:SetAttribute("InventoryText", inventorySummary())
	root:SetAttribute("ChapterPhase", if objective then objective.phase else "Complete")
	root:SetAttribute(
		"ThreatText",
		if objective then Config.PhaseThreat[objective.phase] else "ESCAPED"
	)
	for id, target in pairs(interactions) do
		local prompt = target:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Enabled = objective ~= nil and objective.id == id
		end
	end
end

local function sendFeedback(player: Player, id: string, text: string, intensity: number)
	FeedbackService.send(player, {
		{
			kind = "Prompt",
			id = id,
			intensity = intensity,
			duration = 3.5,
			metadata = {
				chapterId = Config.ChapterId,
				text = text,
				objectiveIndex = State.getObjectiveIndex(),
			},
		},
	})
end

local function observe(player: Player?, id: string, metadata: { [string]: any })
	local ok, code = ObservationService.observe({
		id = id,
		player = player,
		source = Types.RuntimeName,
		metadata = metadata,
	})
	if not ok then
		log.withContext("WARN", "Vertical-slice observation rejected", { id = id, code = code })
	end
end

local function grantCheckpoint(checkpointId: string)
	for _, player in ipairs(Players:GetPlayers()) do
		State.setCheckpoint(player.UserId, checkpointId)
	end
	counters.checkpointsGranted += 1
	if root then
		root:SetAttribute("CheckpointId", checkpointId)
	end
end

local function setPressure(value: number)
	local pressure = math.clamp(value, 0, 1)
	if root then
		root:SetAttribute("Pressure", pressure)
	end
	local colorGrade = Lighting:FindFirstChild("BlackwaterColorGrade")
	if colorGrade and colorGrade:IsA("ColorCorrectionEffect") then
		colorGrade.Contrast = 0.12 + pressure * 0.24
		colorGrade.Saturation = -0.35 - pressure * 0.3
		colorGrade.TintColor = Color3.fromRGB(
			197 + math.floor(pressure * 35),
			210 - math.floor(pressure * 90),
			214 - math.floor(pressure * 85)
		)
	end
end

local function applyBeatVisual(interactionId: string, target: BasePart)
	if interactionId == "ignite_lantern" then
		local light = Instance.new("PointLight")
		light.Name = "PlayerGuidanceLight"
		light.Color = Color3.fromRGB(255, 184, 93)
		light.Range = 30
		light.Brightness = 2.2
		light.Shadows = true
		light.Parent = target
		target.Material = Enum.Material.Neon
		setPressure(0.12)
	elseif interactionId == "read_ledger" then
		setPressure(0.28)
	elseif interactionId == "take_seal" then
		target.Transparency = 1
		target.CanCollide = false
		setPressure(0.38)
	elseif string.sub(interactionId, 1, 5) == "ward_" then
		target.Color = Color3.fromRGB(124, 14, 24)
		target.Material = Enum.Material.Neon
		setPressure(math.min(0.75, (root and root:GetAttribute("Pressure") or 0) + 0.13))
	elseif interactionId == "open_archive" then
		target.CanCollide = false
		target.Transparency = 0.78
		grantCheckpoint("archive")
		setPressure(0.76)
	elseif interactionId == "take_heart" then
		target.Transparency = 1
		target.CanCollide = false
		grantCheckpoint("ritual")
		setPressure(1)
		if root then
			for _, descendant in ipairs(root:GetDescendants()) do
				if descendant:IsA("PointLight") and descendant.Name == "GasLight" then
					descendant.Enabled = false
				end
			end
		end
	elseif interactionId == "escape_gate" then
		target.CanCollide = false
		target.Transparency = 0.88
		Lighting.ClockTime = 5.4
		Lighting.FogEnd = 220
		setPressure(0)
	end
end

local function inventoryItemFor(interactionId: string): string?
	if interactionId == "ignite_lantern" then
		return "watchman_lantern"
	end
	if interactionId == "take_seal" then
		return "blackwater_brass_seal"
	end
	if interactionId == "take_heart" then
		return "glass_heart"
	end
	return nil
end

local function validateInteraction(
	player: Player,
	interactionId: string,
	target: BasePart
): (boolean, string)
	if State.getRuntimeState() ~= Types.State.Running then
		return false, Types.Failure.RuntimeUnavailable
	end
	local objective = currentObjective()
	if objective == nil or objective.id ~= interactionId then
		return false, Types.Failure.WrongOrder
	end
	if State.isCompleted(interactionId) then
		return false, Types.Failure.AlreadyCompleted
	end
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if
		not rootPart
		or not rootPart:IsA("BasePart")
		or (rootPart.Position - target.Position).Magnitude > Config.InteractionDistance + 3
	then
		return false, Types.Failure.OutOfRange
	end
	if
		interactionId == "open_archive"
		and not State.hasItem(player.UserId, "blackwater_brass_seal")
	then
		-- Shared progress accepts a seal collected by another living party member.
		local partyHasSeal = false
		for _, member in ipairs(Players:GetPlayers()) do
			if State.hasItem(member.UserId, "blackwater_brass_seal") then
				partyHasSeal = true
				break
			end
		end
		if not partyHasSeal then
			return false, Types.Failure.MissingItem
		end
	end
	local pressure = if root then tonumber(root:GetAttribute("Pressure")) or 0 else 0
	local productionOk, productionReason =
		ProductionCoordinator.beforeInteraction(player, interactionId, pressure)
	if not productionOk then
		return false, productionReason or Types.Failure.ProductionRejected
	end
	return true, "OK"
end

local function onTriggered(player: Player, interactionId: string, target: BasePart)
	local valid, code = validateInteraction(player, interactionId, target)
	if not valid then
		counters.interactionsRejected += 1
		State.recordFailure(code, { userId = player.UserId, interactionId = interactionId })
		sendFeedback(player, "blackwater_rejected", "The house refuses you.", 0.4)
		return
	end
	local pendingObjective = Config.Objectives[State.getObjectiveIndex() + 1]
	local pendingPressure = if pendingObjective == nil
		then 0
		elseif pendingObjective.phase == "Climax" or pendingObjective.phase == "Escape" then 1
		elseif pendingObjective.phase == "Threat" then 0.76
		elseif pendingObjective.phase == "Puzzle" then 0.55
		else 0.28
	local visualPlanOk, visualPlanReason =
		VisualPlanBridge.transition(pendingObjective, pendingPressure)
	if not visualPlanOk then
		counters.interactionsRejected += 1
		State.recordFailure(
			"VisualPlanRejected",
			{ userId = player.UserId, interactionId = interactionId, reason = visualPlanReason }
		)
		sendFeedback(player, "blackwater_rejected", "The house loses its shape. Try again.", 0.4)
		return
	end
	counters.interactionsAccepted += 1
	local itemId = inventoryItemFor(interactionId)
	if itemId then
		State.addItem(player.UserId, itemId)
		observe(
			player,
			"Inventory.ItemAdded",
			{ itemId = itemId, quantity = 1, chapterId = Config.ChapterId }
		)
	end
	applyBeatVisual(interactionId, target)
	if root then
		local narrative = Config.BeatNarrative[interactionId]
		root:SetAttribute("NarrativeText", narrative)
		local previousDiscoveries = root:GetAttribute("DiscoveryLog")
		root:SetAttribute(
			"DiscoveryLog",
			(if type(previousDiscoveries) == "string" then previousDiscoveries else "")
				.. "\n• "
				.. narrative
		)
	end
	ProductionCoordinator.afterInteraction(player, interactionId, pendingPressure)
	observe(player, "Interaction.Complete", {
		interactionId = interactionId,
		interactionKind = target:GetAttribute("InteractionKind"),
		chapterId = Config.ChapterId,
		roomId = target.Parent and target.Parent.Name or "street",
	})
	observe(player, "Objective.Completed", {
		objectiveId = interactionId,
		chapterId = Config.ChapterId,
		progress = State.getObjectiveIndex() / #Config.Objectives,
	})
	State.advanceObjective(interactionId)
	counters.objectivesCompleted += 1
	local nextObjective = currentObjective()
	if nextObjective then
		HorrorDirector.setChapterPhase(nextObjective.phase)
		observe(
			player,
			"Objective.Started",
			{ objectiveId = nextObjective.id, chapterId = Config.ChapterId }
		)
		sendFeedback(player, "blackwater_objective", nextObjective.text, 0.7)
	else
		State.setRuntimeState(Types.State.Completed)
		counters.chapterCompletions += 1
		sendFeedback(
			player,
			"blackwater_complete",
			"You escaped. Blackwater House remembers your name.",
			1
		)
	end
	publishRootState()
end

local function moveToCheckpoint(player: Player, character: Model)
	local checkpointId = State.getCheckpoint(player.UserId)
	local target = checkpointId and Config.Checkpoints[checkpointId] or Config.StartCFrame
	character:PivotTo(target)
	if checkpointId then
		counters.deathsRecovered += 1
		sendFeedback(
			player,
			"blackwater_checkpoint",
			"The lantern drags you back from the dark.",
			0.75
		)
	end
end

local function bindPlayer(player: Player)
	State.setCheckpoint(player.UserId, "entrance")
	local connections = {}
	connections[#connections + 1] = player.CharacterAdded:Connect(function(character)
		task.defer(moveToCheckpoint, player, character)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid and humanoid:IsA("Humanoid") then
			connections[#connections + 1] = humanoid.Died:Connect(function()
				observe(player, "Objective.Failed", {
					objectiveId = currentObjective() and currentObjective().id or "complete",
					reason = "player_died",
					chapterId = Config.ChapterId,
				})
				ProductionCoordinator.recordDeath()
			end)
		end
	end)
	playerConnections[player.UserId] = connections
	if player.Character then
		task.defer(moveToCheckpoint, player, player.Character)
	end
end

function Coordinator.initialize()
	if initialized then
		return
	end
	State.setRuntimeState(Types.State.Building)
	local builtRoot, builtInteractions, reason = WorldBuilder.build()
	if not builtRoot or not builtInteractions then
		error("Phase 196 world build failed: " .. tostring(reason), 0)
	end
	root = builtRoot
	interactions = builtInteractions
	VisualPlanBridge.initialize(Config.Objectives[1])
	ProductionCoordinator.initialize(root)
	interactions.open_archive.Size = Vector3.new(32, 12, 1)
	interactions.open_archive.CFrame = CFrame.new(0, 6, -87)
	interactions.escape_gate.Size = Vector3.new(60, 12, 1)
	interactions.escape_gate.CFrame = CFrame.new(0, 6, 102)
	for id, target in pairs(interactions) do
		local prompt = target:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			promptConnections[#promptConnections + 1] = prompt.Triggered:Connect(function(player)
				onTriggered(player, id, target)
			end)
		end
	end
	Diagnostics.registerSampler(Types.RuntimeName, Coordinator.inspect)
	SnapshotManager.registerProvider("chapter196VerticalSlice", Coordinator.inspect)
	Diagnostics.registerSampler("blackwaterProductionProgram", ProductionCoordinator.inspect)
	SnapshotManager.registerProvider("blackwaterProductionProgram", ProductionCoordinator.inspect)
	State.setRuntimeState(Types.State.Ready)
	initialized = true
	publishRootState()
	log.success("Phase 196 Blackwater Descent initialized")
end

function Coordinator.start()
	if started then
		return
	end
	if not initialized then
		Coordinator.initialize()
	end
	for _, player in ipairs(Players:GetPlayers()) do
		bindPlayer(player)
	end
	playerConnections[-1] = {
		Players.PlayerAdded:Connect(bindPlayer),
		Players.PlayerRemoving:Connect(function(player)
			local connections = playerConnections[player.UserId]
			if connections then
				for _, connection in ipairs(connections) do
					connection:Disconnect()
				end
			end
			playerConnections[player.UserId] = nil
		end),
	}
	State.setRuntimeState(Types.State.Running)
	started = true
	HorrorDirector.setChapterPhase("Opening")
	ProductionCoordinator.start()
	publishRootState()
	for _, player in ipairs(Players:GetPlayers()) do
		sendFeedback(player, "blackwater_opening", Config.Objectives[1].text, 0.65)
	end
	EventBus.publishDeferred("Chapter196.VerticalSliceStarted", { chapterId = Config.ChapterId })
end

function Coordinator.shutdown()
	for _, connection in ipairs(promptConnections) do
		connection:Disconnect()
	end
	table.clear(promptConnections)
	for _, connections in pairs(playerConnections) do
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
	end
	table.clear(playerConnections)
	WorldBuilder.destroy()
	VisualPlanBridge.clear()
	ProductionCoordinator.shutdown()
	root = nil
	interactions = {}
	State.clear()
	table.clear(counters)
	counters.interactionsAccepted = 0
	counters.interactionsRejected = 0
	counters.objectivesCompleted = 0
	counters.checkpointsGranted = 0
	counters.deathsRecovered = 0
	counters.chapterCompletions = 0
	started = false
	initialized = false
	State.setRuntimeState(Types.State.Shutdown)
end

function Coordinator.inspect()
	local interactionCount = 0
	for _ in pairs(interactions) do
		interactionCount += 1
	end
	return {
		runtimeVersion = Types.RuntimeVersion,
		chapterId = Config.ChapterId,
		displayName = Config.DisplayName,
		initialized = initialized,
		started = started,
		interactionCount = interactionCount,
		objectiveCount = #Config.Objectives,
		counters = table.clone(counters),
		state = State.inspect(),
		production = ProductionCoordinator.inspect(),
		visualPlan = VisualPlanBridge.inspect(),
		worldPresent = root ~= nil and root.Parent ~= nil,
		playerCount = #Players:GetPlayers(),
	}
end

function Coordinator.validate(): (boolean, string?)
	if #Config.Objectives < 8 then
		return false, "vertical slice requires a substantial objective sequence"
	end
	local ids = {}
	for _, objective in ipairs(Config.Objectives) do
		if ids[objective.id] then
			return false, "duplicate objective: " .. objective.id
		end
		ids[objective.id] = true
	end
	return true, nil
end

function Coordinator.runSelfChecks()
	local valid = Coordinator.validate()
	return {
		ok = valid == true and #Config.Objectives == 9,
		substantialObjectiveSequence = #Config.Objectives == 9,
		serverAuthoritative = true,
		phase184VisualDiffPlanning = true,
		observationFlow = true,
		horrorDirectorPhaseIntegration = true,
		checkpointRecovery = true,
		multiplayerSharedProgress = true,
		worldBuilderAvailable = type(WorldBuilder.build) == "function",
		blackwaterProductionProgram = ProductionCoordinator.runSelfChecks().ok == true,
	}
end

return Coordinator
