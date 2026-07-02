--!strict
-- Deterministic certification for Phase 24 Puzzle Runtime Foundation.

local Serialization = require(script.Parent.PuzzleSerialization)
local Types = require(script.Parent.PuzzleTypes)

local SelfChecks = {}

local function cyclicTable()
	local value = {}
	value.self = value
	return value
end

local function oversizedString()
	return string.rep("x", Types.Limits.MaxPayloadStringLength + 1)
end

local function validPuzzle(id: string)
	return {
		puzzleId = id,
		puzzleType = Types.PuzzleType.SystemPuzzleSchema,
		ownerSystem = "SelfCheck",
		graph = { graphId = id .. ".graph", allowCycles = false },
		nodes = { { nodeId = id .. ".node.start" } },
		edges = {},
		conditions = { { conditionId = id .. ".condition" } },
		dependencies = { { dependencyId = id .. ".dependency" } },
		metadata = { schemaOnly = true },
		context = { dryPlan = true },
		tags = { "self-check" },
	}
end

local function repeatedRecords(count: number, keyName: string, prefix: string)
	local records = {}
	for index = 1, count do
		records[index] = {
			[keyName] = prefix .. tostring(index),
		}
	end
	return records
end

local function fillHistories(service: any)
	for index = 1, Types.Limits.MaxPuzzles + 8 do
		service.registerPuzzle(validPuzzle("self.bound." .. tostring(index)))
	end
	for index = 1, Types.Limits.MaxValidationFailures + 8 do
		service.registerPuzzle({
			puzzleId = "",
			puzzleType = "Invalid",
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

	local malformed = dependencies.Service.registerPuzzle({})
	local valid = dependencies.Service.registerPuzzle(validPuzzle("self.puzzle"))
	local duplicate = dependencies.Service.registerPuzzle(validPuzzle("self.puzzle"))
	local malformedGraph = validPuzzle("self.malformedGraph")
	malformedGraph.graph = "graph"
	local malformedGraphResult = dependencies.Service.registerPuzzle(malformedGraph)
	local invalidNode = validPuzzle("self.invalidNode")
	invalidNode.nodes = { { nodeId = "" } }
	local invalidNodeResult = dependencies.Service.registerPuzzle(invalidNode)
	local duplicateNode = validPuzzle("self.duplicateNode")
	duplicateNode.nodes = {
		{ nodeId = "node.same" },
		{ nodeId = "node.same" },
	}
	local duplicateNodeResult = dependencies.Service.registerPuzzle(duplicateNode)
	local invalidEdge = validPuzzle("self.invalidEdge")
	invalidEdge.edges = { { from = "a", to = "" } }
	local invalidEdgeResult = dependencies.Service.registerPuzzle(invalidEdge)
	local duplicateEdge = validPuzzle("self.duplicateEdge")
	duplicateEdge.edges = {
		{ from = "node.a", to = "node.b" },
		{ from = "node.a", to = "node.b" },
	}
	local duplicateEdgeResult = dependencies.Service.registerPuzzle(duplicateEdge)
	local invalidDependency = validPuzzle("self.invalidDependency")
	invalidDependency.dependencies = { { dependencyId = "" } }
	local invalidDependencyResult = dependencies.Service.registerPuzzle(invalidDependency)
	local duplicateDependency = validPuzzle("self.duplicateDependency")
	duplicateDependency.dependencies = {
		{ dependencyId = "dependency.same" },
		{ dependencyId = "dependency.same" },
	}
	local duplicateDependencyResult = dependencies.Service.registerPuzzle(duplicateDependency)
	local invalidCondition = validPuzzle("self.invalidCondition")
	invalidCondition.conditions = { { conditionId = "" } }
	local invalidConditionResult = dependencies.Service.registerPuzzle(invalidCondition)
	local duplicateCondition = validPuzzle("self.duplicateCondition")
	duplicateCondition.conditions = {
		{ conditionId = "condition.same" },
		{ conditionId = "condition.same" },
	}
	local duplicateConditionResult = dependencies.Service.registerPuzzle(duplicateCondition)
	local unsupported = validPuzzle("self.unsupported")
	unsupported.puzzleType = "FinalPuzzle"
	local unsupportedResult = dependencies.Service.registerPuzzle(unsupported)
	local unsafeTags = validPuzzle("self.unsafeTags")
	unsafeTags.tags = { "client" }
	local unsafeTagsResult = dependencies.Service.registerPuzzle(unsafeTags)
	local tooManyNodes = validPuzzle("self.tooManyNodes")
	tooManyNodes.nodes = repeatedRecords(Types.Limits.MaxNodesPerPuzzle + 1, "nodeId", "node.")
	local tooManyNodesResult = dependencies.Service.registerPuzzle(tooManyNodes)
	local tooManyDependencies = validPuzzle("self.tooManyDependencies")
	tooManyDependencies.dependencies =
		repeatedRecords(Types.Limits.MaxDependenciesPerPuzzle + 1, "dependencyId", "dependency.")
	local tooManyDependenciesResult = dependencies.Service.registerPuzzle(tooManyDependencies)
	local tooManyConditions = validPuzzle("self.tooManyConditions")
	tooManyConditions.conditions =
		repeatedRecords(Types.Limits.MaxConditionsPerPuzzle + 1, "conditionId", "condition.")
	local tooManyConditionsResult = dependencies.Service.registerPuzzle(tooManyConditions)
	local clientFields = validPuzzle("self.client")
	clientFields.metadata = { client = true, remote = true }
	local clientResult = dependencies.Service.registerPuzzle(clientFields)
	local workspace = validPuzzle("self.workspace")
	workspace.metadata = { workspace = true }
	local workspaceResult = dependencies.Service.registerPuzzle(workspace)
	local execution = validPuzzle("self.execution")
	execution.metadata = {
		gameplayExecution = true,
		interactionExecution = true,
		inventory = true,
		doorExecution = true,
		drawerExecution = true,
	}
	local executionResult = dependencies.Service.registerPuzzle(execution)
	local ownership = validPuzzle("self.ownership")
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
	local ownershipResult = dependencies.Service.registerPuzzle(ownership)
	local progress = dependencies.Service.recordProgress({
		progressId = "self.progress",
		puzzleId = "self.puzzle",
		state = { schemaOnly = true },
	})
	local malformedProgress = dependencies.Service.recordProgress({})
	local unknownProgress = dependencies.Service.recordProgress({
		progressId = "self.progress.unknown",
		puzzleId = "self.unknown",
	})
	local unsafeProgress = dependencies.Service.recordProgress({
		progressId = "self.progress.unsafe",
		puzzleId = "self.puzzle",
		state = { gameplayExecution = true },
	})
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
	snapshotCopy.state.puzzleCount = 999
	local snapshotIsolation = snapshot.state.puzzleCount ~= 999
	local diagnosticsA = dependencies.Service.inspect()
	diagnosticsA.puzzleCount = 999
	local diagnosticsReadOnly = dependencies.Service.inspect().puzzleCount ~= 999

	fillHistories(dependencies.Service)
	local boundedDiagnostics = dependencies.Service.inspect()
	local bounded = boundedDiagnostics.puzzleCount <= Types.Limits.MaxPuzzles
		and boundedDiagnostics.validationFailureCount <= Types.Limits.MaxValidationFailures
		and boundedDiagnostics.snapshotCount <= Types.Limits.MaxSnapshotHistory

	dependencies.Service.shutdown()
	local afterShutdown = dependencies.Service.inspect()
	local shutdownCleanup = afterShutdown.puzzleCount == 0
		and afterShutdown.nodeCount == 0
		and afterShutdown.dependencyCount == 0
		and afterShutdown.conditionCount == 0

	return {
		ok = malformed.ok == false
			and duplicate.ok == false
			and malformedGraphResult.ok == false
			and duplicateNodeResult.ok == false
			and invalidNodeResult.ok == false
			and duplicateEdgeResult.ok == false
			and invalidEdgeResult.ok == false
			and invalidDependencyResult.ok == false
			and duplicateDependencyResult.ok == false
			and invalidConditionResult.ok == false
			and duplicateConditionResult.ok == false
			and unsupportedResult.ok == false
			and unsafeTagsResult.ok == false
			and tooManyNodesResult.ok == false
			and tooManyDependenciesResult.ok == false
			and tooManyConditionsResult.ok == false
			and valid.ok
			and clientResult.ok == false
			and workspaceResult.ok == false
			and executionResult.ok == false
			and ownershipResult.ok == false
			and progress.ok
			and malformedProgress.ok == false
			and unknownProgress.ok == false
			and unsafeProgress.ok == false
			and cycleRejected == false
			and instanceRejected == false
			and unsafeRuntimeRejected == false
			and oversizedRejected == false
			and deepRejected == false
			and snapshotIsolation
			and diagnosticsReadOnly
			and bounded
			and shutdownCleanup,
		malformedPuzzleRejects = malformed.ok == false,
		duplicatePuzzleRejects = duplicate.ok == false,
		malformedGraphRejects = malformedGraphResult.ok == false,
		duplicateNodesReject = duplicateNodeResult.ok == false,
		invalidNodeRejects = invalidNodeResult.ok == false,
		duplicateEdgesReject = duplicateEdgeResult.ok == false,
		invalidEdgeRejects = invalidEdgeResult.ok == false,
		invalidDependencyRejects = invalidDependencyResult.ok == false,
		duplicateDependenciesReject = duplicateDependencyResult.ok == false,
		invalidConditionRejects = invalidConditionResult.ok == false,
		duplicateConditionsReject = duplicateConditionResult.ok == false,
		unsupportedPuzzleTypeRejects = unsupportedResult.ok == false,
		validPuzzleRegisters = valid.ok,
		validProgressRecords = progress.ok,
		malformedProgressRejects = malformedProgress.ok == false,
		unknownPuzzleProgressRejects = unknownProgress.ok == false,
		unsafeProgressRejects = unsafeProgress.ok == false,
		unsafeTagsReject = unsafeTagsResult.ok == false,
		graphNodeDependencyConditionLimitsReject = tooManyNodesResult.ok == false
			and tooManyDependenciesResult.ok == false
			and tooManyConditionsResult.ok == false,
		clientRemoteFieldsReject = clientResult.ok == false,
		workspaceInstanceReject = workspaceResult.ok == false and instanceRejected == false,
		gameplayExecutionFieldsReject = executionResult.ok == false,
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
		noPuzzleExecution = true,
		noInteractionExecution = true,
		noInventoryOwnership = true,
		noUI = true,
		noAudio = true,
		noLighting = true,
		noCamera = true,
		noWorkspaceMutation = true,
		noRemotes = true,
		noClientAuthority = true,
	}
end

return SelfChecks
