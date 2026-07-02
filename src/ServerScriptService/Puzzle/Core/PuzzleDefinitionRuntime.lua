--!strict
-- Bounded store and registration for puzzle schemas.

local Serialization = require(script.Parent.PuzzleSerialization)
local Types = require(script.Parent.PuzzleTypes)
local Validation = require(script.Parent.PuzzleValidation)

local Definition = {}

local puzzles: { [string]: any } = {}
local puzzleOrder: { string } = {}
local progress: { any } = {}
local validationFailures: { any } = {}
local snapshotHistory: { any } = {}

local function trimList(list: { any }, limit: number)
	while #list > limit do
		table.remove(list, 1)
	end
end

local function countMap(map: { [string]: any }): number
	local count = 0
	for _ in pairs(map) do
		count += 1
	end
	return count
end

local function trimPuzzles()
	while #puzzleOrder > Types.Limits.MaxPuzzles do
		local id = table.remove(puzzleOrder, 1)
		if id ~= nil then
			puzzles[id] = nil
		end
	end
end

function Definition.exists(puzzleId: string): boolean
	return puzzles[puzzleId] ~= nil
end

function Definition.register(schema: any): (boolean, string?)
	local ok, reason = Validation.schema(schema)
	if not ok then
		return false, reason
	end
	if Definition.exists(schema.puzzleId) then
		return false, "duplicate puzzleId"
	end
	puzzles[schema.puzzleId] = Serialization.deepCopy({
		puzzleId = schema.puzzleId,
		puzzleType = schema.puzzleType,
		ownerSystem = schema.ownerSystem,
		graph = schema.graph,
		nodes = schema.nodes or {},
		edges = schema.edges or {},
		conditions = schema.conditions or {},
		dependencies = schema.dependencies or {},
		metadata = schema.metadata or {},
		context = schema.context or {},
		tags = schema.tags or {},
		registeredAt = os.clock(),
	})
	table.insert(puzzleOrder, schema.puzzleId)
	trimPuzzles()
	return true, nil
end

function Definition.recordProgress(record: any)
	table.insert(progress, Serialization.deepCopy(record))
	trimList(progress, Types.Limits.MaxProgressRecords)
end

function Definition.recordValidationFailure(reason: string, payload: any?)
	table.insert(validationFailures, {
		reason = reason,
		payload = Serialization.diagnosticCopy(payload),
		createdAt = os.clock(),
	})
	trimList(validationFailures, Types.Limits.MaxValidationFailures)
end

function Definition.recordSnapshot(summary: any)
	table.insert(snapshotHistory, Serialization.deepCopy(summary))
	trimList(snapshotHistory, Types.Limits.MaxSnapshotHistory)
end

function Definition.inspect()
	local nodeCount = 0
	local dependencyCount = 0
	local conditionCount = 0
	for _, puzzle in pairs(puzzles) do
		for _ in pairs(puzzle.nodes or {}) do
			nodeCount += 1
		end
		for _ in pairs(puzzle.dependencies or {}) do
			dependencyCount += 1
		end
		for _ in pairs(puzzle.conditions or {}) do
			conditionCount += 1
		end
	end
	return {
		puzzleCount = countMap(puzzles),
		nodeCount = nodeCount,
		graphCount = countMap(puzzles),
		dependencyCount = dependencyCount,
		conditionCount = conditionCount,
		progressCount = #progress,
		puzzles = Serialization.deepCopy(puzzles),
		progress = Serialization.deepCopy(progress),
		validationFailureCount = #validationFailures,
		validationFailures = Serialization.deepCopy(validationFailures),
		snapshotCount = #snapshotHistory,
		snapshotHistory = Serialization.deepCopy(snapshotHistory),
		limits = Serialization.deepCopy(Types.Limits),
	}
end

function Definition.clear()
	table.clear(puzzles)
	table.clear(puzzleOrder)
	table.clear(progress)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return Definition
