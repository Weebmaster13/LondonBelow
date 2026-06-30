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

return DirectorApproval
