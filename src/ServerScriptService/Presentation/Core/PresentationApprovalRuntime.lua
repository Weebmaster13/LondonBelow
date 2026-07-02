--!strict
-- Approval verification for presentation requests.

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)
local Validation = require(script.Parent.PresentationValidation)

local ApprovalRuntime = {}

local approvalsByPresentation: { [string]: any } = {}
local approvalOrder: { string } = {}

local function countEntries(values: any): number
	local count = 0
	for _ in pairs(values) do
		count += 1
	end
	return count
end

local function countStored(): number
	local count = 0
	for _, approvals in pairs(approvalsByPresentation) do
		count += countEntries(approvals)
	end
	return count
end

function ApprovalRuntime.verify(presentationId: string, approvals: any): (boolean, string?)
	if type(approvals) ~= "table" or next(approvals) == nil then
		return false, "missing approvals"
	end
	if countEntries(approvals) > Types.Limits.MaxApprovalsPerRequest then
		return false, "approval count exceeds limit"
	end
	local seen: { [string]: boolean } = {}
	local approvedCount = 0
	for _, approval in pairs(approvals) do
		if type(approval) ~= "table" then
			return false, "approval must be a table"
		end
		if not Validation.id(approval.approvalId) then
			return false, "approvalId is required"
		end
		if seen[approval.approvalId] == true then
			return false, "duplicate approvalId"
		end
		seen[approval.approvalId] = true
		if approval.status == Types.Status.Approved then
			approvedCount += 1
		elseif approval.status == Types.Status.Rejected then
			return false, "approval rejected"
		elseif approval.status == Types.Status.Expired then
			return false, "approval expired"
		elseif approval.status ~= Types.Status.Pending then
			return false, "approval status is invalid"
		end
	end
	if approvedCount == 0 then
		return false, "missing approved approvals"
	end
	approvalsByPresentation[presentationId] = Serialization.deepCopy(approvals)
	table.insert(approvalOrder, presentationId)
	while #approvalOrder > Types.Limits.MaxRequests do
		local id = table.remove(approvalOrder, 1)
		if id ~= nil then
			approvalsByPresentation[id] = nil
		end
	end
	return true, nil
end

function ApprovalRuntime.inspect()
	return {
		approvalCount = countStored(),
		approvalsByPresentation = Serialization.deepCopy(approvalsByPresentation),
	}
end

function ApprovalRuntime.clear()
	table.clear(approvalsByPresentation)
	table.clear(approvalOrder)
end

return ApprovalRuntime
