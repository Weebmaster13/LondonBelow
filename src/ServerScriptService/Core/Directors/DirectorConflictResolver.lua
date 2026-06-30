--!strict

local DirectorApproval = require(script.Parent.DirectorApproval)
local Types = require(script.Parent.DirectorTypes)

local DirectorConflictResolver = {}

local activeByConflictGroup: { [string]: Types.DirectorRequest } = {}
local conflictCount = 0

local function isExpired(request: Types.DirectorRequest): boolean
	return os.clock() > request.expiresAt
end

function DirectorConflictResolver.resolve(request: Types.DirectorRequest): Types.DirectorApproval?
	if isExpired(request) then
		return DirectorApproval.create(
			request.requestId,
			"Expired",
			"Request expired before routing.",
			"DirectorConflictResolver",
			nil,
			{}
		)
	end

	if request.targetDirector == "Performance" and table.find(request.tags, "Override") ~= nil then
		return DirectorApproval.create(
			request.requestId,
			"Approved",
			"Performance override hook approved.",
			"DirectorConflictResolver",
			nil,
			{ override = true }
		)
	end

	if request.conflictGroup == nil then
		return nil
	end

	local active = activeByConflictGroup[request.conflictGroup]

	if active == nil or isExpired(active) then
		activeByConflictGroup[request.conflictGroup] = request
		return nil
	end

	local currentWeight = Types.PriorityWeight[request.priority] or 0
	local activeWeight = Types.PriorityWeight[active.priority] or 0

	if currentWeight < activeWeight then
		conflictCount += 1
		return DirectorApproval.create(
			request.requestId,
			"Deferred",
			"Deferred because a higher priority request owns this conflict group.",
			"DirectorConflictResolver",
			nil,
			{ conflictGroup = request.conflictGroup }
		)
	end

	activeByConflictGroup[request.conflictGroup] = request
	return nil
end

function DirectorConflictResolver.inspect()
	return {
		activeByConflictGroup = table.clone(activeByConflictGroup),
		conflictCount = conflictCount,
	}
end

function DirectorConflictResolver.clear()
	table.clear(activeByConflictGroup)
	conflictCount = 0
end

return DirectorConflictResolver
