--!strict

local InventoryState = {}
local Config = require(script.Parent.Parent.Core.GameplayConfig)
local Copy = require(script.Parent.Parent.Core.GameplayCopy)

local personal: { [number]: { [string]: any } } = {}
local partyInventory: { [string]: { [string]: any } } = {}
local recentChanges: { any } = {}
local counters = {
	added = 0,
	removed = 0,
	rejected = 0,
}

local function remember(change: any)
	table.insert(recentChanges, change)
	while #recentChanges > 120 do
		table.remove(recentChanges, 1)
	end
end

local function containerFor(userId: number): { [string]: any }
	local container = personal[userId]
	if container == nil then
		container = {}
		personal[userId] = container
	end
	return container
end

function InventoryState.add(userId: number, item: any)
	local container = containerFor(userId)
	local existing = container[item.itemId]
	if existing == nil then
		container[item.itemId] = {
			itemId = item.itemId,
			kind = item.kind,
			count = math.max(1, item.count or 1),
			metadata = Copy.dictionary(item.metadata or {}),
		}
	else
		existing.count = math.max(0, existing.count + math.max(1, item.count or 1))
	end
	counters.added += 1
	remember({ at = os.clock(), kind = "Added", userId = userId, itemId = item.itemId })
	return table.clone(container[item.itemId])
end

function InventoryState.remove(userId: number, itemId: string, count: number): boolean
	local container = containerFor(userId)
	local existing = container[itemId]
	if existing == nil or existing.count < count then
		counters.rejected += 1
		return false
	end
	existing.count -= count
	if existing.count <= 0 then
		container[itemId] = nil
	end
	counters.removed += 1
	remember({ at = os.clock(), kind = "Removed", userId = userId, itemId = itemId })
	return true
end

function InventoryState.has(userId: number, itemId: string): boolean
	local container = containerFor(userId)
	return container[itemId] ~= nil and container[itemId].count > 0
end

function InventoryState.itemCountFor(userId: number): number
	local container = containerFor(userId)
	local count = 0

	for _ in pairs(container) do
		count += 1
	end

	return count
end

function InventoryState.inspect()
	local copiedPersonal = {}
	local itemCount = 0
	for userId, container in pairs(personal) do
		copiedPersonal[userId] = Copy.dictionary(container)
		for _ in pairs(container) do
			itemCount += 1
		end
	end
	return {
		personal = copiedPersonal,
		partyInventory = Copy.dictionary(partyInventory),
		itemCount = itemCount,
		recentChanges = Copy.array(recentChanges),
		counters = table.clone(counters),
		limits = {
			maxItemsPerPlayer = Config.MaxInventoryItemsPerPlayer,
		},
	}
end

function InventoryState.serialize()
	return InventoryState.inspect()
end

function InventoryState.clear()
	table.clear(personal)
	table.clear(partyInventory)
	table.clear(recentChanges)
	for key in pairs(counters) do
		counters[key] = 0
	end
end

return InventoryState
