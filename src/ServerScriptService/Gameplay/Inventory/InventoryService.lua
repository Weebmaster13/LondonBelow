--!strict

local InventoryDiagnostics = require(script.Parent.InventoryDiagnostics)
local InventoryState = require(script.Parent.InventoryState)
local InventoryValidator = require(script.Parent.InventoryValidator)

local InventoryService = {}

function InventoryService.initialize() end

function InventoryService.addItem(userId: number, item: any): (boolean, string?, any?)
	local valid, reason = InventoryValidator.validateItem(item)
	if not valid then
		return false, reason, nil
	end
	return true, nil, InventoryState.add(userId, item)
end

function InventoryService.removeItem(
	userId: number,
	itemId: string,
	count: number?
): (boolean, string?)
	local removed = InventoryState.remove(userId, itemId, math.max(1, count or 1))
	return removed, if removed then nil else "item is missing or insufficient"
end

function InventoryService.hasItem(userId: number, itemId: string): boolean
	return InventoryState.has(userId, itemId)
end

function InventoryService.inspect()
	return InventoryDiagnostics.capture({ InventoryState = InventoryState })
end

function InventoryService.validate(): (boolean, string?)
	return InventoryValidator.validate()
end

function InventoryService.runSelfChecks()
	InventoryService.shutdown()
	local addOk = InventoryService.addItem(-13001, {
		itemId = "selfcheck.key",
		kind = "Key",
		count = 1,
		metadata = {},
	})
	local hasItem = InventoryService.hasItem(-13001, "selfcheck.key")
	local removeOk = InventoryService.removeItem(-13001, "selfcheck.key", 1)
	InventoryService.shutdown()
	return {
		ok = addOk == true and hasItem and removeOk == true,
		serverOwnedTruth = true,
	}
end

function InventoryService.shutdown()
	InventoryState.clear()
end

return InventoryService
