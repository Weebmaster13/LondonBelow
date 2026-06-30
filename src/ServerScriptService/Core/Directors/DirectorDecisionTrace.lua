--!strict

local DirectorConfig = require(script.Parent.DirectorConfig)

local DirectorDecisionTrace = {}

local traces: { any } = {}

local function append(event: string, requestId: string, details: { [string]: any }?)
	table.insert(traces, {
		at = os.clock(),
		event = event,
		requestId = requestId,
		details = details or {},
	})

	while #traces > DirectorConfig.TraceLimit do
		table.remove(traces, 1)
	end
end

function DirectorDecisionTrace.submitted(request: any)
	append("request submitted", request.requestId, {
		sourceDirector = request.sourceDirector,
		targetDirector = request.targetDirector,
		requestKind = request.requestKind,
	})
end

function DirectorDecisionTrace.routed(request: any)
	append("routed", request.requestId, {
		targetDirector = request.targetDirector,
	})
end

function DirectorDecisionTrace.directorResponse(request: any, approval: any)
	append("director response", request.requestId, {
		status = approval.status,
		reason = approval.reason,
	})
end

function DirectorDecisionTrace.conflictResolution(request: any, approval: any)
	append("conflict resolution result", request.requestId, {
		status = approval.status,
		reason = approval.reason,
		conflictGroup = request.conflictGroup,
	})
end

function DirectorDecisionTrace.finalApproval(approval: any)
	append("final approval", approval.requestId, {
		status = approval.status,
		reason = approval.reason,
	})
end

function DirectorDecisionTrace.cancelled(requestId: string, reason: string)
	append("cancellation/expiration", requestId, {
		reason = reason,
	})
end

function DirectorDecisionTrace.failure(requestId: string, reason: string)
	append("failure reason", requestId, {
		reason = reason,
	})
end

function DirectorDecisionTrace.inspect()
	return table.clone(traces)
end

function DirectorDecisionTrace.clear()
	table.clear(traces)
end

return DirectorDecisionTrace
