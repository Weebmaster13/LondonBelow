--!strict

local Types = require(script.Parent.RobloxGuiInteractionTypes)

local FocusScope = {}

function FocusScope.resolve(contract: any, controls: { any }): (boolean, { any }?, string?)
	local nodes = {}
	local modalNodes = {}
	for _, node in ipairs(contract.nodes) do
		nodes[node.nodeId] = node
		local metadata = node.accessibility or {}
		if metadata.modal == true and node.properties.Visible ~= false then
			modalNodes[#modalNodes + 1] = node
		end
	end
	if #modalNodes > Types.Limits.maxFocusScopes then
		return false, nil, "focus-scope-budget"
	end
	table.sort(modalNodes, function(a, b)
		local aPriority = (a.accessibility or {}).scopePriority or 0
		local bPriority = (b.accessibility or {}).scopePriority or 0
		if aPriority == bPriority then
			return a.nodeId < b.nodeId
		end
		return aPriority > bPriority
	end)
	local activeModal = modalNodes[1]
	if not activeModal then
		return true, controls
	end
	local eligible = {}
	for _, control in ipairs(controls) do
		local cursor = nodes[control.nodeId]
		while cursor do
			if cursor.nodeId == activeModal.nodeId then
				control.scopeId = (activeModal.accessibility or {}).scopeId
				eligible[#eligible + 1] = control
				break
			end
			cursor = nodes[cursor.parentNodeId]
		end
	end
	return true, eligible, (activeModal.accessibility or {}).scopeId
end

return table.freeze(FocusScope)
