--!strict

local Registry = {}
local active = nil :: any

function Registry.get()
	return active
end

function Registry.commit(record: any)
	active = record
end

function Registry.clear()
	active = nil
end

function Registry.snapshot()
	if not active then
		return nil
	end
	return {
		contractId = active.contractId,
		revision = active.revision,
		rootName = active.root and active.root.Name or nil,
		nodeCount = active.nodeCount,
	}
end

return Registry
