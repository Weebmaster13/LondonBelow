--!strict
-- Schema registration boundary for inventory items. It does not execute item use.

local InventoryItemRuntime = {}

function InventoryItemRuntime.register(state: any, item: any): (boolean, string?)
	return state.registerItem(item)
end

return InventoryItemRuntime
