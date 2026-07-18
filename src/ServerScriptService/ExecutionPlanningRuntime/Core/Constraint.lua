--!strict

local Types = require(script.Parent.Types)
local Validation = require(script.Parent.Validation)

local Constraint = {}

function Constraint.evaluate(
	nodesById: { [string]: any },
	constraints: { any }
): (boolean, string?, { [string]: number })
	if #constraints > Types.Limits.MaxConstraints then
		return false, Types.ResultCode.InvalidSchema .. ": constraint limit exceeded", {}
	end
	local summary = {
		total = 0,
		required = 0,
		blocking = 0,
		satisfied = 0,
	}
	local seen = {}
	for _, constraint in ipairs(constraints) do
		local ok, reason = Validation.constraint(constraint)
		if not ok then
			return false, reason, summary
		end
		if seen[constraint.constraintId] then
			return false, Types.ResultCode.ConstraintRejected .. ": duplicate constraint", summary
		end
		seen[constraint.constraintId] = true
		if nodesById[constraint.nodeId] == nil then
			return false,
				Types.ResultCode.ConstraintRejected .. ": constraint node missing",
				summary
		end
		summary.total += 1
		if constraint.required then
			summary.required += 1
		end
		if constraint.constraintKind == Types.ConstraintKind.RuntimeBlocked then
			summary.blocking += 1
		else
			summary.satisfied += 1
		end
	end
	return true, nil, summary
end

return Constraint
