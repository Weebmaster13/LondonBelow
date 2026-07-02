--!strict
-- Approval verification for execution requests. Approvals are schema records only.

local Serialization = require(script.Parent.ExecutionSerialization)
local Types = require(script.Parent.ExecutionTypes)
local Validation = require(script.Parent.ExecutionValidation)

local ApprovalRuntime = {}

local approvalsByExecution: { [string]: any } = {}
local approvalOrder: { string } = {}

local function countEntries(values: any): number
	local count = 0
	for _ in pairs(values) do
		count += 1
	end
	return count
end

local function countStoredApprovals(): number
	local count = 0
	for _, approvals in pairs(approvalsByExecution) do
		count += countEntries(approvals)
	end
	return count
end

function ApprovalRuntime.verify(executionId: string, approvals: any): (boolean, string?)
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
		elseif approval.status == Types.Status.Cancelled then
			return false, "approval cancelled"
		elseif approval.status == Types.Status.Expired then
			return false, "approval expired"
		elseif approval.status ~= Types.Status.Pending then
			return false, "approval status is invalid"
		end
	end
	if approvedCount == 0 then
		return false, "missing approved approvals"
	end
	approvalsByExecution[executionId] = Serialization.deepCopy(approvals)
	table.insert(approvalOrder, executionId)
	while #approvalOrder > Types.Limits.MaxRequests do
		local oldId = table.remove(approvalOrder, 1)
		if oldId ~= nil then
			approvalsByExecution[oldId] = nil
		end
	end
	return true, nil
end

function ApprovalRuntime.inspect()
	return {
		approvalCount = countStoredApprovals(),
		approvalsByExecution = Serialization.deepCopy(approvalsByExecution),
	}
end

function ApprovalRuntime.clear()
	table.clear(approvalsByExecution)
	table.clear(approvalOrder)
end

return ApprovalRuntime
