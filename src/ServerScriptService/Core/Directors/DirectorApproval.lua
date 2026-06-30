--!strict

local Types = require(script.Parent.DirectorTypes)

local DirectorApproval = {}

function DirectorApproval.create(
	requestId: string,
	status: Types.ApprovalStatus,
	reason: string,
	decidedBy: string,
	modifiedRequest: Types.DirectorRequest?,
	diagnostics: { [string]: any }?
): Types.DirectorApproval
	return {
		requestId = requestId,
		status = status,
		reason = reason,
		decidedBy = decidedBy,
		decidedAt = os.clock(),
		modifiedRequest = modifiedRequest,
		diagnostics = diagnostics or {},
	}
end

function DirectorApproval.validate(approval: any, expectedRequestId: string?): (boolean, string?)
	if type(approval) ~= "table" then
		return false, "Approval must be a table"
	end

	if type(approval.requestId) ~= "string" or approval.requestId == "" then
		return false, "Approval requires requestId"
	end

	if expectedRequestId ~= nil and approval.requestId ~= expectedRequestId then
		return false, "Approval requestId does not match request"
	end

	if type(approval.status) ~= "string" or not Types.ValidApprovalStatuses[approval.status] then
		return false, "Approval has invalid status"
	end

	if type(approval.reason) ~= "string" or approval.reason == "" then
		return false, "Approval requires reason"
	end

	if type(approval.decidedBy) ~= "string" or approval.decidedBy == "" then
		return false, "Approval requires decidedBy"
	end

	if type(approval.decidedAt) ~= "number" then
		return false, "Approval requires decidedAt"
	end

	if approval.status == "Modified" and type(approval.modifiedRequest) ~= "table" then
		return false, "Modified approval requires modifiedRequest"
	end

	if
		approval.modifiedRequest ~= nil
		and approval.modifiedRequest.requestId ~= approval.requestId
	then
		return false, "Modified approval must preserve requestId"
	end

	if type(approval.diagnostics) ~= "table" then
		return false, "Approval requires diagnostics table"
	end

	return true, nil
end

return DirectorApproval
