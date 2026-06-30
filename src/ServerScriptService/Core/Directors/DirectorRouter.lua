--!strict

local DirectorApproval = require(script.Parent.DirectorApproval)
local DirectorConflictResolver = require(script.Parent.DirectorConflictResolver)
local DirectorDecisionTrace = require(script.Parent.DirectorDecisionTrace)
local DirectorRequest = require(script.Parent.DirectorRequest)
local Types = require(script.Parent.DirectorTypes)

local DirectorRouter = {}

function DirectorRouter.route(
	request: any,
	directorsByName: { [string]: Types.Director }
): Types.DirectorApproval
	local valid, err = DirectorRequest.validate(request)

	if not valid then
		local requestId = if type(request) == "table"
				and type(request.requestId) == "string"
			then request.requestId
			else "<malformed>"
		DirectorDecisionTrace.failure(requestId, err or "Malformed request")
		local approval = DirectorApproval.create(
			requestId,
			"Rejected",
			err or "Malformed request.",
			"DirectorRouter",
			nil,
			{}
		)
		DirectorDecisionTrace.finalApproval(approval)
		return approval
	end

	local typedRequest = request :: Types.DirectorRequest
	DirectorDecisionTrace.submitted(typedRequest)

	if os.clock() > typedRequest.expiresAt then
		DirectorDecisionTrace.cancelled(typedRequest.requestId, "Expired")
		local approval = DirectorApproval.create(
			typedRequest.requestId,
			"Expired",
			"Request expired before routing.",
			"DirectorRouter",
			nil,
			{}
		)
		DirectorDecisionTrace.finalApproval(approval)
		return approval
	end

	local target = directorsByName[typedRequest.targetDirector]

	if target == nil then
		DirectorDecisionTrace.failure(typedRequest.requestId, "Unknown target Director")
		local approval = DirectorApproval.create(
			typedRequest.requestId,
			"Rejected",
			"Unknown target Director.",
			"DirectorRouter",
			nil,
			{}
		)
		DirectorDecisionTrace.finalApproval(approval)
		return approval
	end

	DirectorDecisionTrace.routed(typedRequest)

	local conflictApproval = DirectorConflictResolver.resolve(typedRequest)

	if conflictApproval ~= nil then
		DirectorDecisionTrace.conflictResolution(typedRequest, conflictApproval)
		DirectorDecisionTrace.finalApproval(conflictApproval)
		return conflictApproval
	end

	local ok, approval = pcall(function()
		return target:requestApproval(typedRequest)
	end)

	if not ok then
		DirectorDecisionTrace.failure(typedRequest.requestId, tostring(approval))
		local failedApproval = DirectorApproval.create(
			typedRequest.requestId,
			"Rejected",
			"Target Director failed during approval.",
			"DirectorRouter",
			nil,
			{ error = tostring(approval) }
		)
		DirectorDecisionTrace.finalApproval(failedApproval)
		return failedApproval
	end

	DirectorDecisionTrace.directorResponse(typedRequest, approval)
	DirectorDecisionTrace.finalApproval(approval)

	return approval
end

return DirectorRouter
