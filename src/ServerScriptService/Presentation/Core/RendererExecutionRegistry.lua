--!strict

local Serialization = require(script.Parent.PresentationSerialization)

local Registry = {}
local workloads = {}

function Registry.assign(rendererId: string, executionSessionId: string)
	workloads[rendererId] = workloads[rendererId]
		or { rendererId = rendererId, assigned = {}, active = {}, completed = {} }
	local workload = workloads[rendererId]
	workload.assigned[#workload.assigned + 1] = executionSessionId
	return Serialization.deepCopy(workload)
end

function Registry.activate(rendererId: string, executionSessionId: string)
	workloads[rendererId] = workloads[rendererId]
		or { rendererId = rendererId, assigned = {}, active = {}, completed = {} }
	workloads[rendererId].active[#workloads[rendererId].active + 1] = executionSessionId
	return Serialization.deepCopy(workloads[rendererId])
end

function Registry.complete(rendererId: string, executionSessionId: string)
	workloads[rendererId] = workloads[rendererId]
		or { rendererId = rendererId, assigned = {}, active = {}, completed = {} }
	workloads[rendererId].completed[#workloads[rendererId].completed + 1] = executionSessionId
	return Serialization.deepCopy(workloads[rendererId])
end

function Registry.inspect()
	return Serialization.deepCopy(workloads)
end

function Registry.clear()
	table.clear(workloads)
end

return Registry
