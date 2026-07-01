--!strict

local InventoryDiagnostics = {}

function InventoryDiagnostics.capture(dependencies: { [string]: any })
	local state = dependencies.InventoryState.inspect()
	return {
		itemCount = state.itemCount,
		personal = state.personal,
		partyInventory = state.partyInventory,
		recentChanges = state.recentChanges,
		counters = state.counters,
		health = {
			healthy = true,
			status = "Ready",
			message = "Inventory Runtime owns server item truth only.",
		},
	}
end

return InventoryDiagnostics
