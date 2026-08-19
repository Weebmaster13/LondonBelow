--!strict

local Types = require(script.Parent.RobloxGuiInteractionTypes)

local Hardening = {}

function Hardening.validate(contract: any): (boolean, string?)
	local modalScopeIds = {}
	local initialFocusByScope = {}
	local nodes = {}
	local scopeCount = 0
	for _, node in ipairs(contract.nodes) do
		nodes[node.nodeId] = node
		local metadata = node.accessibility or {}
		local scopeId = metadata.scopeId or "__root"
		if metadata.modal == true then
			if modalScopeIds[scopeId] then
				return false, "duplicate-modal-scope"
			end
			modalScopeIds[scopeId] = true
			scopeCount += 1
			if metadata.focusable == true then
				return false, "modal-container-focusable"
			end
		elseif metadata.scopePriority ~= nil then
			return false, "scope-priority-without-modal"
		end
	end
	for _, node in ipairs(contract.nodes) do
		local metadata = node.accessibility or {}
		if metadata.initialFocus == true then
			if metadata.focusable ~= true or metadata.disabled == true then
				return false, "invalid-initial-focus"
			end
			local scopeId = "__root"
			local cursor = node
			while cursor do
				local cursorMetadata = cursor.accessibility or {}
				if cursorMetadata.modal == true then
					scopeId = cursorMetadata.scopeId
					break
				end
				cursor = nodes[cursor.parentNodeId]
			end
			if initialFocusByScope[scopeId] then
				return false, "duplicate-initial-focus"
			end
			initialFocusByScope[scopeId] = node.nodeId
		end
	end
	if scopeCount > Types.Limits.maxFocusScopes then
		return false, "focus-scope-budget"
	end
	return true
end

return table.freeze(Hardening)
