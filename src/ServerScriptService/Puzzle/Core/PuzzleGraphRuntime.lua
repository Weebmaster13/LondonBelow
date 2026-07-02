--!strict
-- Puzzle graph schema validation helpers.

local Validation = require(script.Parent.PuzzleValidation)

local Graph = {}

function Graph.validate(graph: any, nodes: any, edges: any): (boolean, string?)
	local graphOk, graphReason = Validation.graph(graph)
	if not graphOk then
		return false, graphReason
	end
	local nodesOk, nodesReason = Validation.nodes(nodes)
	if not nodesOk then
		return false, nodesReason
	end
	return Validation.edges(edges)
end

return Graph
