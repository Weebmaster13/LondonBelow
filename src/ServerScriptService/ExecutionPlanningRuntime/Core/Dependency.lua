--!strict

local Types = require(script.Parent.Types)
local Validation = require(script.Parent.Validation)

local Dependency = {}

local function fail(code: string, reason: string): (boolean, string?)
	return false, code .. ": " .. reason
end

function Dependency.validate(
	nodesById: { [string]: any },
	dependencies: { any }
): (boolean, string?)
	if #dependencies > Types.Limits.MaxDependencies then
		return fail(Types.ResultCode.InvalidSchema, "dependency limit exceeded")
	end
	local seen = {}
	local adjacency = {}
	for nodeId in pairs(nodesById) do
		adjacency[nodeId] = {}
	end
	for _, dependency in ipairs(dependencies) do
		local ok, reason = Validation.dependency(dependency)
		if not ok then
			return ok, reason
		end
		if seen[dependency.dependencyId] then
			return fail(Types.ResultCode.DuplicateDependency, dependency.dependencyId)
		end
		seen[dependency.dependencyId] = true
		local fromNode = nodesById[dependency.fromNodeId]
		local toNode = nodesById[dependency.toNodeId]
		if fromNode == nil or toNode == nil then
			return fail(Types.ResultCode.MissingDependency, dependency.dependencyId)
		end
		if
			fromNode.authorityOwner ~= toNode.authorityOwner
			and dependency.dependencyKind == Types.DependencyKind.Requires
		then
			return fail(Types.ResultCode.IllegalOwnership, dependency.dependencyId)
		end
		if dependency.requiredVersion ~= toNode.version then
			return fail(Types.ResultCode.VersionMismatch, dependency.dependencyId)
		end
		table.insert(adjacency[dependency.fromNodeId], dependency.toNodeId)
	end

	local visiting = {}
	local visited = {}
	local function visit(nodeId: string): boolean
		if visiting[nodeId] then
			return false
		end
		if visited[nodeId] then
			return true
		end
		visiting[nodeId] = true
		for _, targetId in ipairs(adjacency[nodeId]) do
			if not visit(targetId) then
				return false
			end
		end
		visiting[nodeId] = nil
		visited[nodeId] = true
		return true
	end
	for nodeId in pairs(nodesById) do
		if not visit(nodeId) then
			return fail(Types.ResultCode.CyclicDependency, nodeId)
		end
	end
	return true, nil
end

return Dependency
