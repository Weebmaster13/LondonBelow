--!strict

local InventoryDiagnostics = require(script.Parent.InventoryDiagnostics)
local InventoryState = require(script.Parent.InventoryState)
local InventoryValidator = require(script.Parent.InventoryValidator)
local Config = require(script.Parent.Parent.Core.GameplayConfig)
local ObservationService =
	require(game:GetService("ServerScriptService").Horror.Observation.ObservationService)

local InventoryService = {}

function InventoryService.initialize() end

function InventoryService.addItem(userId: number, item: any): (boolean, string?, any?)
	local valid, reason = InventoryValidator.validateItem(item)
	if not valid then
		return false, reason, nil
	end
	if
		not InventoryState.has(userId, item.itemId)
		and InventoryState.itemCountFor(userId) >= Config.MaxInventoryItemsPerPlayer
	then
		return false, "inventory item limit reached", nil
	end
	local stack = InventoryState.add(userId, item)
	ObservationService.observe({
		id = "Inventory.ItemAdded",
		source = "InventoryService",
		metadata = {
			userId = userId,
			itemId = item.itemId,
			itemKind = item.kind,
			count = stack.count,
		},
	})
	return true, nil, stack
end

function InventoryService.removeItem(
	userId: number,
	itemId: string,
	count: number?
): (boolean, string?)
	local removed = InventoryState.remove(userId, itemId, math.max(1, count or 1))
	if removed then
		ObservationService.observe({
			id = "Inventory.ItemRemoved",
			source = "InventoryService",
			metadata = {
				userId = userId,
				itemId = itemId,
				itemKind = "Unknown",
			},
		})
	end
	return removed, if removed then nil else "item is missing or insufficient"
end

function InventoryService.hasItem(userId: number, itemId: string): boolean
	return InventoryState.has(userId, itemId)
end

function InventoryService.inspect()
	return InventoryDiagnostics.capture({ InventoryState = InventoryState })
end

function InventoryService.serialize()
	return InventoryState.serialize()
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
