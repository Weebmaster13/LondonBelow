--!strict

local PuzzleDiagnostics = require(script.Parent.PuzzleDiagnostics)
local PuzzleGraph = require(script.Parent.PuzzleGraph)
local PuzzleHintService = require(script.Parent.PuzzleHintService)
local PuzzleRegistry = require(script.Parent.PuzzleRegistry)
local PuzzleState = require(script.Parent.PuzzleState)
local PuzzleValidator = require(script.Parent.PuzzleValidator)
local ObservationService =
	require(game:GetService("ServerScriptService").Horror.Observation.ObservationService)

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
	local status = PuzzleState.start(puzzleId)
	ObservationService.observe({
		id = "Puzzle.Started",
		source = "PuzzleService",
		metadata = { puzzleId = puzzleId },
	})
	return true, nil, status
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
		ObservationService.observe({
			id = "Puzzle.WrongInput",
			source = "PuzzleService",
			metadata = {
				puzzleId = puzzleId,
				nodeId = nodeId,
				reason = reason or "dependency rejected",
			},
		})
		return false, reason, nil
	end
	local nextStatus = PuzzleState.completeNode(puzzleId, nodeId)
	ObservationService.observe({
		id = "Puzzle.NodeCompleted",
		source = "PuzzleService",
		metadata = {
			puzzleId = puzzleId,
			nodeId = nodeId,
		},
	})
	local allComplete = true
	for _, completionNodeId in ipairs(definition.completionNodeIds) do
		if nextStatus.completedNodes[completionNodeId] ~= true then
			allComplete = false
			break
		end
	end
	if allComplete then
		nextStatus = PuzzleState.complete(puzzleId)
		ObservationService.observe({
			id = "Puzzle.Completed",
			source = "PuzzleService",
			metadata = { puzzleId = puzzleId },
		})
	end
	return true, nil, nextStatus
end

function PuzzleService.requestHint(puzzleId: string): (boolean, string, string?)
	local definition = PuzzleRegistry.get(puzzleId)
	if definition == nil then
		PuzzleState.recordRejected()
		return false, "unknown puzzle", nil
	end
	ObservationService.observe({
		id = "Puzzle.HintRequested",
		source = "PuzzleService",
		metadata = { puzzleId = puzzleId },
	})
	local ok, reason, hint = PuzzleHintService.requestHint(puzzleId, definition, os.clock())
	if ok then
		local status = PuzzleState.get(puzzleId)
		ObservationService.observe({
			id = "Puzzle.HintShown",
			source = "PuzzleService",
			metadata = {
				puzzleId = puzzleId,
				hintIndex = if status ~= nil then status.hintsShown else 1,
			},
		})
	end
	return ok, reason, hint
end

function PuzzleService.failPuzzle(puzzleId: string, reason: string?): (boolean, string?, any?)
	if PuzzleRegistry.get(puzzleId) == nil then
		PuzzleState.recordRejected()
		return false, "unknown puzzle", nil
	end
	local status = PuzzleState.fail(puzzleId, reason)
	ObservationService.observe({
		id = "Puzzle.Failed",
		source = "PuzzleService",
		metadata = {
			puzzleId = puzzleId,
			reason = reason or "unspecified",
		},
	})
	return true, nil, status
end

function PuzzleService.inspect()
	return PuzzleDiagnostics.capture({
		PuzzleRegistry = PuzzleRegistry,
		PuzzleState = PuzzleState,
		PuzzleHintService = PuzzleHintService,
	})
end

function PuzzleService.serialize()
	return {
		registry = PuzzleRegistry.serialize(),
		state = PuzzleState.serialize(),
		hints = PuzzleHintService.inspect(),
	}
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
