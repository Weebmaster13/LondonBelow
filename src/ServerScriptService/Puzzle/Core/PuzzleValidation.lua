--!strict
-- Validation boundary for server-owned puzzle schemas.

local Serialization = require(script.Parent.PuzzleSerialization)
local Types = require(script.Parent.PuzzleTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"animation",
	"audio",
	"chapter",
	"chapter0",
	"chapter1",
	"client",
	"complete",
	"cutscene",
	"dialogue",
	"doorExecution",
	"drawerExecution",
	"execute",
	"gameplayExecution",
	"horrorPacing",
	"instance",
	"interactionExecution",
	"inventory",
	"lighting",
	"monsterAI",
	"narrative",
	"remote",
	"save",
	"story",
	"ui",
	"workspace",
}

local FORBIDDEN_LOOKUP: { [string]: boolean } = {}

for _, field in ipairs(FORBIDDEN_FIELDS) do
	FORBIDDEN_LOOKUP[string.lower(field)] = true
end

local function validId(value: any): boolean
	return type(value) == "string"
		and value ~= ""
		and #value <= 140
		and string.match(value, "^[%w%._%-:]+$") ~= nil
end

local function supportedPuzzleType(value: any): boolean
	for _, puzzleType in pairs(Types.PuzzleType) do
		if value == puzzleType then
			return true
		end
	end
	return false
end

local function forbidden(payload: any, depth: number): (boolean, string?)
	if type(payload) ~= "table" then
		return true, nil
	end
	if depth > Types.Limits.MaxPayloadDepth then
		return false, "puzzle payload depth exceeds limit"
	end
	for key in pairs(payload) do
		if type(key) == "string" and FORBIDDEN_LOOKUP[string.lower(key)] == true then
			return false, "puzzle payload contains forbidden field: " .. key
		end
	end
	for _, nested in pairs(payload) do
		local ok, reason = forbidden(nested, depth + 1)
		if not ok then
			return false, reason
		end
	end
	return true, nil
end

local function validateArray(value: any, label: string): (boolean, string?)
	if value == nil then
		return true, nil
	end
	if type(value) ~= "table" then
		return false, label .. " must be a table"
	end
	return true, nil
end

local function validateTags(tags: any): (boolean, string?)
	if tags == nil then
		return true, nil
	end
	if type(tags) ~= "table" then
		return false, "tags must be a table"
	end
	if #tags > Types.Limits.MaxTags then
		return false, "tag count exceeds limit"
	end
	for _, tag in ipairs(tags) do
		if not validId(tag) then
			return false, "tag is invalid"
		end
		if FORBIDDEN_LOOKUP[string.lower(tag)] == true then
			return false, "tag uses forbidden ownership domain: " .. tag
		end
	end
	return true, nil
end

function Validation.safePayload(payload: any): (boolean, string?)
	local ok, reason = Serialization.validateSerializable(payload)
	if not ok then
		return false, reason
	end
	return forbidden(payload, 0)
end

function Validation.id(value: any): boolean
	return validId(value)
end

function Validation.graph(graph: any): (boolean, string?)
	if type(graph) ~= "table" then
		return false, "graph must be a table"
	end
	if not validId(graph.graphId) then
		return false, "graphId is required"
	end
	return Validation.safePayload(graph)
end

function Validation.nodes(nodes: any): (boolean, string?)
	local ok, reason = validateArray(nodes, "nodes")
	if not ok then
		return false, reason
	end
	if #(nodes or {}) > Types.Limits.MaxNodesPerPuzzle then
		return false, "node count exceeds limit"
	end
	local seen: { [string]: boolean } = {}
	for _, node in pairs(nodes or {}) do
		if type(node) ~= "table" or not validId(node.nodeId) then
			return false, "invalid node"
		end
		if seen[node.nodeId] == true then
			return false, "duplicate nodeId"
		end
		seen[node.nodeId] = true
	end
	return Validation.safePayload(nodes or {})
end

function Validation.edges(edges: any): (boolean, string?)
	local ok, reason = validateArray(edges, "edges")
	if not ok then
		return false, reason
	end
	if #(edges or {}) > Types.Limits.MaxEdgesPerPuzzle then
		return false, "edge count exceeds limit"
	end
	local seen: { [string]: boolean } = {}
	for _, edge in pairs(edges or {}) do
		if type(edge) ~= "table" or not validId(edge.from) or not validId(edge.to) then
			return false, "invalid edge"
		end
		local edgeId = tostring(edge.from) .. "->" .. tostring(edge.to)
		if seen[edgeId] == true then
			return false, "duplicate edge"
		end
		seen[edgeId] = true
	end
	return Validation.safePayload(edges or {})
end

function Validation.conditions(conditions: any): (boolean, string?)
	local ok, reason = validateArray(conditions, "conditions")
	if not ok then
		return false, reason
	end
	if #(conditions or {}) > Types.Limits.MaxConditionsPerPuzzle then
		return false, "condition count exceeds limit"
	end
	local seen: { [string]: boolean } = {}
	for _, condition in pairs(conditions or {}) do
		if type(condition) ~= "table" or not validId(condition.conditionId) then
			return false, "invalid condition"
		end
		if seen[condition.conditionId] == true then
			return false, "duplicate conditionId"
		end
		seen[condition.conditionId] = true
	end
	return Validation.safePayload(conditions or {})
end

function Validation.dependencies(dependencies: any): (boolean, string?)
	local ok, reason = validateArray(dependencies, "dependencies")
	if not ok then
		return false, reason
	end
	if #(dependencies or {}) > Types.Limits.MaxDependenciesPerPuzzle then
		return false, "dependency count exceeds limit"
	end
	local seen: { [string]: boolean } = {}
	for _, dependency in pairs(dependencies or {}) do
		if type(dependency) ~= "table" or not validId(dependency.dependencyId) then
			return false, "invalid dependency"
		end
		if seen[dependency.dependencyId] == true then
			return false, "duplicate dependencyId"
		end
		seen[dependency.dependencyId] = true
	end
	return Validation.safePayload(dependencies or {})
end

function Validation.schema(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "puzzle schema must be a table"
	end
	local safe, safeReason = Validation.safePayload(schema)
	if not safe then
		return false, safeReason
	end
	if not validId(schema.puzzleId) then
		return false, "puzzleId is required"
	end
	if not supportedPuzzleType(schema.puzzleType) then
		return false, "unsupported puzzle type"
	end
	if not validId(schema.ownerSystem) then
		return false, "ownerSystem is required"
	end
	local graphOk, graphReason = Validation.graph(schema.graph)
	if not graphOk then
		return false, graphReason
	end
	local nodesOk, nodesReason = Validation.nodes(schema.nodes)
	if not nodesOk then
		return false, nodesReason
	end
	local edgesOk, edgesReason = Validation.edges(schema.edges)
	if not edgesOk then
		return false, edgesReason
	end
	local conditionsOk, conditionsReason = Validation.conditions(schema.conditions)
	if not conditionsOk then
		return false, conditionsReason
	end
	local dependenciesOk, dependenciesReason = Validation.dependencies(schema.dependencies)
	if not dependenciesOk then
		return false, dependenciesReason
	end
	if schema.metadata ~= nil and type(schema.metadata) ~= "table" then
		return false, "metadata must be a table"
	end
	if schema.context ~= nil and type(schema.context) ~= "table" then
		return false, "context must be a table"
	end
	local tagsOk, tagsReason = validateTags(schema.tags)
	if not tagsOk then
		return false, tagsReason
	end
	return true, nil
end

function Validation.validate(): (boolean, string?)
	if Types.Mode ~= "ServerAuthoritativePuzzleSchemaRuntime" then
		return false, "Puzzle Runtime must remain server-authoritative schema runtime"
	end
	return true, nil
end

return Validation
