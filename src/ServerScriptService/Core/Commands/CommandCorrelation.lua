--!strict

local Serialization = require(script.Parent.CommandSerialization)

local Correlation = {}
local workflows: { [string]: any } = {}

function Correlation.record(command: any, result: any?)
	local correlationId = command.correlationId or command.commandId
	local workflow = workflows[correlationId]
	if workflow == nil then
		workflow = {
			correlationId = correlationId,
			commandIds = {},
			owners = {},
			failures = {},
		}
		workflows[correlationId] = workflow
	end
	table.insert(workflow.commandIds, command.commandId)
	workflow.owners[command.ownerRuntime] = true
	if result ~= nil and result.ok == false then
		table.insert(workflow.failures, {
			commandId = command.commandId,
			code = result.code,
			reason = result.failureReason,
		})
	end
end

function Correlation.inspect()
	return Serialization.deepCopy(workflows)
end

function Correlation.clear()
	table.clear(workflows)
end

return Correlation
