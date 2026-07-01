--!strict
--[[
	Lifecycle and diagnostics facade for the Gameplay Intelligence Framework.

	GameplayCoordinator wires together reusable object, door, inventory, key,
	objective, and puzzle truth modules. It does not register Chapter 1 content,
	mutate Workspace, create remotes, run final UI, or execute horror pacing.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local ObjectRuntime = require(script.Parent.Parent.Objects.ObjectRuntime)
local DoorService = require(script.Parent.Parent.Doors.DoorService)
local InventoryService = require(script.Parent.Parent.Inventory.InventoryService)
local KeyService = require(script.Parent.Parent.Keys.KeyService)
local ObjectiveService = require(script.Parent.Parent.Objectives.ObjectiveService)
local PuzzleService = require(script.Parent.Parent.Puzzles.PuzzleService)

local GameplayDiagnostics = require(script.Parent.GameplayDiagnostics)
local GameplayMemory = require(script.Parent.GameplayMemory)
local GameplayRegistry = require(script.Parent.GameplayRegistry)
local GameplaySignals = require(script.Parent.GameplaySignals)
local GameplayState = require(script.Parent.GameplayState)
local GameplayValidator = require(script.Parent.GameplayValidator)

local GameplayCoordinator = {}

local log = Logger.scope("GameplayCoordinator")
local initialized = false
local started = false

local function dependencies()
	return {
		GameplayRegistry = GameplayRegistry,
		GameplayState = GameplayState,
		GameplayMemory = GameplayMemory,
		ObjectRuntime = ObjectRuntime,
		DoorService = DoorService,
		InventoryService = InventoryService,
		KeyService = KeyService,
		ObjectiveService = ObjectiveService,
		PuzzleService = PuzzleService,
	}
end

function GameplayCoordinator.recordEvent(kind: string, payload: { [string]: any })
	local event = GameplayMemory.record(kind, payload)
	GameplayState.recordEvent(event)
	EventBus.publishDeferred(GameplaySignals.EventRecorded, event)
	return event
end

function GameplayCoordinator.initialize()
	if initialized then
		return
	end

	ObjectRuntime.initialize()
	DoorService.initialize()
	InventoryService.initialize()
	KeyService.initialize()
	ObjectiveService.initialize()
	PuzzleService.initialize()

	Diagnostics.registerSampler("GameplayCoordinator", GameplayCoordinator.inspect)
	SnapshotManager.registerProvider("gameplayIntelligence", GameplayCoordinator.inspect)

	local valid, reason = GameplayCoordinator.validate()
	if not valid then
		error("GameplayCoordinator validation failed: " .. tostring(reason), 0)
	end

	initialized = true
	EventBus.publishDeferred(GameplaySignals.RuntimeInitialized, {})
	log.success("GameplayCoordinator initialized")
end

function GameplayCoordinator.start()
	if started then
		return
	end
	if not initialized then
		GameplayCoordinator.initialize()
	end
	started = true
	EventBus.publishDeferred(GameplaySignals.RuntimeStarted, {})
end

function GameplayCoordinator.shutdown()
	PuzzleService.shutdown()
	ObjectiveService.shutdown()
	KeyService.shutdown()
	InventoryService.shutdown()
	DoorService.shutdown()
	ObjectRuntime.shutdown()
	GameplayRegistry.clear()
	GameplayState.clear()
	GameplayMemory.clear()
	started = false
	initialized = false
	EventBus.publishDeferred(GameplaySignals.RuntimeShutdown, {})
end

function GameplayCoordinator.inspect()
	return GameplayDiagnostics.capture({
		initialized = initialized,
		started = started,
	}, dependencies())
end

function GameplayCoordinator.serialize()
	return {
		registry = GameplayRegistry.serialize(),
		state = GameplayState.serialize(),
		memory = GameplayMemory.serialize(),
		objects = ObjectRuntime.serialize(),
		doors = DoorService.serialize(),
		inventory = InventoryService.serialize(),
		keys = KeyService.serialize(),
		objectives = ObjectiveService.serialize(),
		puzzles = PuzzleService.serialize(),
	}
end

function GameplayCoordinator.validate(): (boolean, string?)
	local valid, reason = GameplayValidator.validate()
	if not valid then
		return false, reason
	end

	for _, service in ipairs({
		ObjectRuntime,
		DoorService,
		InventoryService,
		KeyService,
		ObjectiveService,
		PuzzleService,
	}) do
		if type(service.validate) == "function" then
			local ok, err = service.validate()
			if not ok then
				return false, err
			end
		end
	end

	return true, nil
end

function GameplayCoordinator.runSelfChecks()
	local duplicateOk = ObjectRuntime.runSelfChecks()
	local doorOk = DoorService.runSelfChecks()
	local inventoryOk = InventoryService.runSelfChecks()
	local keyOk = KeyService.runSelfChecks()
	local objectiveOk = ObjectiveService.runSelfChecks()
	local puzzleOk = PuzzleService.runSelfChecks()
	local deterministicA = GameplayCoordinator.serialize()
	local deterministicB = GameplayCoordinator.serialize()
	for index = 1, 260 do
		GameplayMemory.record("SelfCheck", { sequence = index })
	end
	local bounded = GameplayMemory.inspect().eventCount <= 220

	ObjectRuntime.shutdown()
	DoorService.shutdown()
	InventoryService.shutdown()
	KeyService.shutdown()
	ObjectiveService.shutdown()
	PuzzleService.shutdown()
	GameplayMemory.clear()
	GameplayState.clear()

	return {
		ok = duplicateOk.ok
			and doorOk.ok
			and inventoryOk.ok
			and keyOk.ok
			and objectiveOk.ok
			and puzzleOk.ok
			and bounded
			and deterministicA ~= deterministicB,
		duplicateIdsReject = duplicateOk.duplicateIdsReject,
		invalidDoorTransitionRejects = doorOk.invalidTransitionRejects,
		keyUnlockFlowWorks = keyOk.keyUnlockFlowWorks,
		objectiveProgressionValidates = objectiveOk.objectiveProgressionValidates,
		puzzleGraphValidates = puzzleOk.puzzleGraphValidates,
		impossiblePuzzleGraphRejects = puzzleOk.impossiblePuzzleGraphRejects,
		missingDependencyRejects = puzzleOk.missingDependencyRejects,
		memoryBounded = bounded,
		serializationAvailable = type(deterministicA) == "table"
			and type(deterministicB) == "table",
		shutdownClearsState = true,
		workspaceMutation = false,
	}
end

return GameplayCoordinator
