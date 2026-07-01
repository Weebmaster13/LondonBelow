--!strict

local PuzzleDiagnostics = require(script.Parent.PuzzleDiagnostics)
local PuzzleGraph = require(script.Parent.PuzzleGraph)
local PuzzleHintService = require(script.Parent.PuzzleHintService)
local PuzzleRegistry = require(script.Parent.PuzzleRegistry)
local PuzzleState = require(script.Parent.PuzzleState)
local PuzzleValidator = require(script.Parent.PuzzleValidator)

local PuzzleService = {}

function PuzzleService.initialize() end

function PuzzleService.registerPuzzle(definition: any): (boolean, string?)
	return PuzzleRegistry.register(definition)
end

function PuzzleService.startPuzzle(puzzleId: string): (boolean, string?, any?)
	if PuzzleRegistry.get(puzzleId) == nil then
		PuzzleState.recordRejected()
		return false, "unknown puzzle", nil
	end
	return true, nil, PuzzleState.start(puzzleId)
end

function PuzzleService.completeNode(puzzleId: string, nodeId: string): (boolean, string?, any?)
	local definition = PuzzleRegistry.get(puzzleId)
	local status = PuzzleState.get(puzzleId)
	if definition == nil or status == nil then
		PuzzleState.recordRejected()
		return false, "unknown puzzle", nil
	end
	local ok, reason = PuzzleGraph.canCompleteNode(definition, status.completedNodes, nodeId)
	if not ok then
		PuzzleState.recordWrongInput(puzzleId)
		return false, reason, nil
	end
	local nextStatus = PuzzleState.completeNode(puzzleId, nodeId)
	local allComplete = true
	for _, completionNodeId in ipairs(definition.completionNodeIds) do
		if nextStatus.completedNodes[completionNodeId] ~= true then
			allComplete = false
			break
		end
	end
	if allComplete then
		nextStatus = PuzzleState.complete(puzzleId)
	end
	return true, nil, nextStatus
end

function PuzzleService.requestHint(puzzleId: string): (boolean, string, string?)
	local definition = PuzzleRegistry.get(puzzleId)
	if definition == nil then
		PuzzleState.recordRejected()
		return false, "unknown puzzle", nil
	end
	return PuzzleHintService.requestHint(puzzleId, definition, os.clock())
end

function PuzzleService.inspect()
	return PuzzleDiagnostics.capture({
		PuzzleRegistry = PuzzleRegistry,
		PuzzleState = PuzzleState,
		PuzzleHintService = PuzzleHintService,
	})
end

function PuzzleService.validate(): (boolean, string?)
	return PuzzleValidator.validate()
end

function PuzzleService.runSelfChecks()
	PuzzleService.shutdown()
	local validDefinition = {
		id = "selfcheck.puzzle",
		displayName = "Self Check Puzzle",
		nodes = {
			{
				id = "a",
				dependencies = {},
				requiredItems = {},
				requiredObjectStates = {},
				cooperative = false,
				metadata = {},
			},
			{
				id = "b",
				dependencies = { "a" },
				requiredItems = {},
				requiredObjectStates = {},
				cooperative = true,
				metadata = {},
			},
		},
		failStates = {},
		completionNodeIds = { "b" },
		hints = { "Look for the first dependency.", "Coordinate the final step." },
		fairnessProtection = true,
		directorRequestHooks = { "PuzzleHint" },
		metadata = {},
	}
	local impossibleDefinition = {
		id = "selfcheck.impossible",
		displayName = "Impossible Puzzle",
		nodes = {
			{
				id = "a",
				dependencies = { "b" },
				requiredItems = {},
				requiredObjectStates = {},
				cooperative = false,
				metadata = {},
			},
			{
				id = "b",
				dependencies = { "a" },
				requiredItems = {},
				requiredObjectStates = {},
				cooperative = false,
				metadata = {},
			},
		},
		failStates = {},
		completionNodeIds = { "b" },
		hints = {},
		fairnessProtection = true,
		directorRequestHooks = {},
		metadata = {},
	}
	local validOk = PuzzleService.registerPuzzle(validDefinition)
	local impossibleOk = PuzzleService.registerPuzzle(impossibleDefinition)
	local startOk = PuzzleService.startPuzzle("selfcheck.puzzle")
	local missingDependencyOk = PuzzleService.completeNode("selfcheck.puzzle", "b")
	local nodeAOk = PuzzleService.completeNode("selfcheck.puzzle", "a")
	local nodeBOk = PuzzleService.completeNode("selfcheck.puzzle", "b")
	PuzzleService.shutdown()
	return {
		ok = validOk == true
			and impossibleOk == false
			and startOk == true
			and missingDependencyOk == false
			and nodeAOk == true
			and nodeBOk == true,
		puzzleGraphValidates = validOk == true and nodeAOk == true and nodeBOk == true,
		impossiblePuzzleGraphRejects = impossibleOk == false,
		missingDependencyRejects = missingDependencyOk == false,
	}
end

function PuzzleService.shutdown()
	PuzzleRegistry.clear()
	PuzzleState.clear()
	PuzzleHintService.clear()
end

return PuzzleService
