--!strict

local Catalog = require(script.Parent.RobloxGuiRenderingCatalog)
local Decoder = require(script.Parent.RobloxGuiValueDecoder)
local Types = require(script.Parent.RobloxGuiRenderingTypes)

local Transaction = {}

local function safeDestroy(instance: Instance?)
	if instance then
		pcall(function()
			instance:Destroy()
		end)
	end
end

function Transaction.stage(contract: any, orderedNodes: { any })
	local created = {}
	local root = nil :: Instance?
	for _, node in ipairs(orderedNodes) do
		if not Catalog.supportsClass(node.className) then
			for _, instance in pairs(created) do
				safeDestroy(instance)
			end
			return nil, Types.FailureType.UnsupportedClass
		end
		local okCreate, instanceOrError = pcall(Instance.new, node.className)
		if not okCreate then
			for _, instance in pairs(created) do
				safeDestroy(instance)
			end
			return nil, Types.FailureType.InstanceCreationFailed .. ":" .. tostring(instanceOrError)
		end
		local instance = instanceOrError :: Instance
		created[node.nodeId] = instance
		instance.Name = node.nodeId
		instance:SetAttribute("LondonEngineNodeId", node.nodeId)
		instance:SetAttribute("LondonEngineContractId", contract.contractId)
		instance:SetAttribute("LondonEngineRevision", contract.targetRevision)
		if type(node.accessibility) == "table" then
			instance:SetAttribute("LondonEngineAccessibilityRole", node.accessibility.role)
			instance:SetAttribute("LondonEngineAccessibilityLabel", node.accessibility.label)
		end
		if type(node.responsive) == "table" then
			instance:SetAttribute("LondonEngineResponsivePolicy", node.responsive.policy)
		end
		if type(node.tags) == "table" then
			instance:SetAttribute("LondonEngineTags", table.concat(node.tags, ","))
		end
		local propertyNames = {}
		for propertyName in pairs(node.properties) do
			propertyNames[#propertyNames + 1] = propertyName
		end
		table.sort(propertyNames)
		for _, propertyName in ipairs(propertyNames) do
			local okProperty, propertyError = pcall(function()
				(instance :: any)[propertyName] =
					Decoder.decodeProperty(propertyName, node.properties[propertyName])
			end)
			if not okProperty then
				for _, candidate in pairs(created) do
					safeDestroy(candidate)
				end
				return nil,
					Types.FailureType.PropertyAssignmentFailed
						.. ":"
						.. propertyName
						.. ":"
						.. tostring(propertyError)
			end
		end
		if node.parentNodeId == "PlayerGui" then
			root = instance
		else
			local parent = created[node.parentNodeId]
			if not parent then
				for _, candidate in pairs(created) do
					safeDestroy(candidate)
				end
				return nil, Types.FailureType.MissingParent
			end
			local okParent = pcall(function()
				instance.Parent = parent
			end)
			if not okParent then
				for _, candidate in pairs(created) do
					safeDestroy(candidate)
				end
				return nil, Types.FailureType.ParentAssignmentFailed
			end
		end
	end
	if not root then
		for _, instance in pairs(created) do
			safeDestroy(instance)
		end
		return nil, Types.FailureType.InvalidContract
	end
	return {
		state = Types.TransactionState.Prepared,
		contractId = contract.contractId,
		revision = contract.targetRevision,
		root = root,
		instances = created,
		nodeCount = #orderedNodes,
	}
end

function Transaction.commit(transaction: any, mountTarget: Instance, previous: any)
	transaction.state = Types.TransactionState.Committing
	local ok, commitError = pcall(function()
		transaction.root.Parent = mountTarget
	end)
	if not ok then
		transaction.state = Types.TransactionState.RollingBack
		safeDestroy(transaction.root)
		transaction.state = Types.TransactionState.RolledBack
		return false, Types.FailureType.CommitFailed .. ":" .. tostring(commitError)
	end
	transaction.state = Types.TransactionState.Committed
	if previous and previous.root and previous.root ~= transaction.root then
		safeDestroy(previous.root)
	end
	return true
end

function Transaction.destroy(record: any)
	if record and record.root then
		safeDestroy(record.root)
	end
end

Transaction.discard = Transaction.destroy

return table.freeze(Transaction)
