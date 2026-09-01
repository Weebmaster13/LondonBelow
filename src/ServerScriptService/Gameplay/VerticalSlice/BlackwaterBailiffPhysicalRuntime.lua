--!strict

local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProductionConfig = require(ReplicatedStorage.Config.BlackwaterProductionConfig)

local Runtime = {}
local initialized = false
local bailiffModel: Model? = nil
local rootPart: BasePart? = nil
local generation = 0
local pathRequests = 0
local stuckRecoveries = 0
local telegraphs = 0
local attacks = 0
local misses = 0
local recoveries = 0
local lastKnownPositions: { [number]: Vector3 } = {}
local activeMode = "Dormant"
local encounterState = "Dormant"
local encounterLog = {}

local fairTiming = table.freeze({
	reactionWindow = ProductionConfig.Bailiff.fairness.reactionWindow,
	attackTelegraph = 1.15,
	attackCooldown = 2.6,
	missRecovery = 1.4,
	searchTimeout = 18,
	chaseTimeout = ProductionConfig.Bailiff.fairness.maxHuntSeconds,
	reacquisitionCooldown = 4.5,
})

local function appendEncounter(kind: string, detail: { [string]: any }?)
	if #encounterLog >= 96 then
		table.remove(encounterLog, 1)
	end
	encounterLog[#encounterLog + 1] = table.freeze({
		kind = kind,
		detail = detail or {},
		at = os.clock(),
	})
end

local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Anchored = false
	part.CanCollide = true
	part.Material = Enum.Material.SmoothPlastic
	part.Parent = parent
	return part
end

local function weldToRoot(part: BasePart, root: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
end

function Runtime.initialize(worldRoot: Instance?)
	Runtime.shutdown()
	initialized = true
	activeMode = "Dormant"
	encounterState = "Dormant"
	generation += 1
	if worldRoot == nil then
		return
	end
	local model = Instance.new("Model")
	model.Name = "TheBailiff_ProductionProxy"
	model:SetAttribute("MonsterId", ProductionConfig.Bailiff.id)
	model:SetAttribute("OwnerRuntime", "BlackwaterBailiffPhysicalRuntime")
	model:SetAttribute("FinalArtStatus", "productionProxyReplacementRequired")
	model:SetAttribute("ServerAuthoritative", true)
	model:SetAttribute("EncounterState", encounterState)
	model:SetAttribute("AttackTelegraphSeconds", fairTiming.attackTelegraph)
	model:SetAttribute("ReactionWindowSeconds", fairTiming.reactionWindow)
	model.Parent = worldRoot
	local root = makePart(
		model,
		"HumanoidRootPart",
		Vector3.new(2.4, 7.5, 1.2),
		CFrame.new(0, 4, -92),
		Color3.fromRGB(16, 16, 18)
	)
	root.Name = "HumanoidRootPart"
	local torso = makePart(
		model,
		"CoatMass",
		Vector3.new(3.2, 5.2, 1.4),
		CFrame.new(0, 4.5, -92),
		Color3.fromRGB(22, 20, 22)
	)
	local mask = makePart(
		model,
		"BrassJudgementMask",
		Vector3.new(1.4, 1.8, 0.35),
		CFrame.new(0, 7.4, -91.25),
		Color3.fromRGB(132, 94, 46)
	)
	local chain = makePart(
		model,
		"ReceiptChain",
		Vector3.new(0.25, 4.8, 0.25),
		CFrame.new(1.4, 4.2, -91.2),
		Color3.fromRGB(98, 77, 46)
	)
	torso.Massless = true
	mask.Massless = true
	chain.Massless = true
	weldToRoot(torso, root)
	weldToRoot(mask, root)
	weldToRoot(chain, root)
	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "BailiffHumanoid"
	humanoid.WalkSpeed = 10
	humanoid.JumpPower = 0
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = model
	model.PrimaryPart = root
	bailiffModel = model
	rootPart = root
end

function Runtime.setMode(mode: string)
	activeMode = mode
	encounterState = mode
	if bailiffModel then
		bailiffModel:SetAttribute("BailiffPhysicalMode", mode)
		bailiffModel:SetAttribute("EncounterState", encounterState)
	end
end

function Runtime.telegraphAttack(targetUserId: number, reason: string): (boolean, string?)
	if targetUserId == 0 then
		return false, "InvalidTarget"
	end
	telegraphs += 1
	encounterState = "AttackTelegraph"
	appendEncounter("AttackTelegraph", { targetUserId = targetUserId, reason = reason })
	if bailiffModel then
		bailiffModel:SetAttribute("EncounterState", encounterState)
		bailiffModel:SetAttribute("TelegraphTargetUserId", targetUserId)
		bailiffModel:SetAttribute("TelegraphReason", reason)
	end
	return true, nil
end

function Runtime.resolveAttack(hit: boolean, reason: string): string
	if hit then
		attacks += 1
		encounterState = "Attack"
		appendEncounter("Attack", { reason = reason })
	else
		misses += 1
		encounterState = "Miss"
		appendEncounter("Miss", { reason = reason })
	end
	if bailiffModel then
		bailiffModel:SetAttribute("EncounterState", encounterState)
		bailiffModel:SetAttribute("AttackResolution", if hit then "hit" else "miss")
	end
	return encounterState
end

function Runtime.recover(reason: string)
	recoveries += 1
	encounterState = "Recover"
	appendEncounter("Recover", { reason = reason })
	if bailiffModel then
		bailiffModel:SetAttribute("EncounterState", encounterState)
		bailiffModel:SetAttribute("RecoveryReason", reason)
	end
end

function Runtime.planPath(destination: Vector3): (boolean, string)
	pathRequests += 1
	if rootPart == nil then
		return false, "PhysicalRootUnavailable"
	end
	local ok, pathOrError = pcall(function()
		local path = PathfindingService:CreatePath({
			AgentRadius = 2,
			AgentHeight = 8,
			AgentCanJump = false,
			WaypointSpacing = 5,
		})
		path:ComputeAsync(rootPart.Position, destination)
		return path
	end)
	if not ok then
		return false, "PathCreationFailed"
	end
	local path = pathOrError
	if path.Status ~= Enum.PathStatus.Success then
		return false, "PathBlocked"
	end
	return true, "PathReady"
end

function Runtime.recordLastKnownPosition(userId: number, position: Vector3)
	lastKnownPositions[userId] = position
	if bailiffModel then
		bailiffModel:SetAttribute("LastKnownTargetUserId", userId)
	end
end

function Runtime.safeReposition(cframe: CFrame, reason: string): (boolean, string?)
	if rootPart == nil or bailiffModel == nil then
		return false, "PhysicalRootUnavailable"
	end
	stuckRecoveries += 1
	bailiffModel:PivotTo(cframe)
	bailiffModel:SetAttribute("LastRecoveryReason", reason)
	return true, nil
end

function Runtime.inspect()
	local lastKnownCount = 0
	for _ in pairs(lastKnownPositions) do
		lastKnownCount += 1
	end
	return {
		initialized = initialized,
		modelPresent = bailiffModel ~= nil and bailiffModel.Parent ~= nil,
		rootPresent = rootPart ~= nil and rootPart.Parent ~= nil,
		activeMode = activeMode,
		generation = generation,
		pathRequests = pathRequests,
		stuckRecoveries = stuckRecoveries,
		telegraphs = telegraphs,
		attacks = attacks,
		misses = misses,
		recoveries = recoveries,
		lastKnownCount = lastKnownCount,
		encounterState = encounterState,
		encounterLog = table.clone(encounterLog),
		fairTiming = table.clone(fairTiming),
		finalArtStatus = "productionProxyReplacementRequired",
	}
end

function Runtime.runSelfChecks()
	Runtime.initialize(nil)
	Runtime.setMode("Search")
	local noRootPath = Runtime.planPath(Vector3.new(0, 0, 0))
	Runtime.recordLastKnownPosition(-1, Vector3.new(1, 2, 3))
	local telegraph = Runtime.telegraphAttack(-1, "self_check")
	local miss = Runtime.resolveAttack(false, "self_check")
	Runtime.recover("self_check")
	local snapshot = Runtime.inspect()
	return {
		ok = snapshot.initialized == true
			and snapshot.activeMode == "Search"
			and noRootPath == false
			and snapshot.lastKnownCount == 1
			and telegraph == true
			and miss == "Miss"
			and snapshot.telegraphs == 1
			and snapshot.misses == 1
			and snapshot.recoveries == 1,
		snapshot = snapshot,
	}
end

function Runtime.shutdown()
	if bailiffModel then
		bailiffModel:Destroy()
	end
	bailiffModel = nil
	rootPart = nil
	initialized = false
	activeMode = "Shutdown"
	encounterState = "Shutdown"
	lastKnownPositions = {}
	encounterLog = {}
end

return Runtime
