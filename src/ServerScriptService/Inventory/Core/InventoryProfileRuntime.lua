--!strict
--[[
	Server-owned state store for Phase 25 Inventory Runtime Foundation.

	This module records inventory profiles, item schemas, slot schemas, ownership
	schemas, capacity schemas, eligibility schemas, diagnostics history, and
	snapshot history. It deliberately records schemas only. It does not pick up,
	use, equip, consume, save, unlock, solve, present, replicate, or execute items.
]]

local Serialization = require(script.Parent.InventorySerialization)
local Types = require(script.Parent.InventoryTypes)
local Validation = require(script.Parent.InventoryValidation)

local Runtime = {}

local profiles: { [string]: any } = {}
local profileOrder: { string } = {}
local items: { [string]: any } = {}
local itemOrder: { string } = {}
local slots: { [string]: any } = {}
local ownership: { [string]: any } = {}
local capacity: { [string]: any } = {}
local eligibility: { [string]: any } = {}
local validationFailures: { any } = {}
local snapshotHistory: { any } = {}

local function boundedInsert(list: { any }, value: any, limit: number)
	table.insert(list, value)
	while #list > limit do
		table.remove(list, 1)
	end
end

local function removeProfile(profileId: string)
	local profile = profiles[profileId]
	profiles[profileId] = nil
	capacity[profileId] = nil
	if profile ~= nil and type(profile.slots) == "table" then
		for _, slot in ipairs(profile.slots) do
			if type(slot) == "table" and type(slot.slotId) == "string" then
				slots[slot.slotId] = nil
			end
		end
	end
end

local function removeItem(itemId: string)
	items[itemId] = nil
	ownership[itemId] = nil
	eligibility[itemId] = nil
end

local function countMap(map: { [string]: any }): number
	local count = 0
	for _ in pairs(map) do
		count += 1
	end
	return count
end

function Runtime.hasProfile(profileId: string): boolean
	return profiles[profileId] ~= nil
end

function Runtime.hasItem(itemId: string): boolean
	return items[itemId] ~= nil
end

function Runtime.registerProfile(profile: any): (boolean, string?)
	local ok, reason = Validation.profile(profile)
	if not ok then
		return false, reason
	end
	if Runtime.hasProfile(profile.inventoryProfileId) then
		return false, "duplicate inventoryProfileId"
	end

	local copy = Serialization.deepCopy(profile)
	profiles[copy.inventoryProfileId] = copy
	boundedInsert(profileOrder, copy.inventoryProfileId, Types.Limits.MaxProfiles)
	if #profileOrder == Types.Limits.MaxProfiles then
		for id in pairs(profiles) do
			local found = false
			for _, retainedId in ipairs(profileOrder) do
				if retainedId == id then
					found = true
					break
				end
			end
			if not found then
				removeProfile(id)
			end
		end
	end

	capacity[copy.inventoryProfileId] = Serialization.deepCopy(copy.capacity)
	for _, slot in ipairs(copy.slots) do
		slots[slot.slotId] = Serialization.deepCopy(slot)
	end

	return true, nil
end

function Runtime.registerItem(item: any): (boolean, string?)
	local ok, reason = Validation.item(item)
	if not ok then
		return false, reason
	end
	if Runtime.hasItem(item.itemId) then
		return false, "duplicate itemId"
	end

	local copy = Serialization.deepCopy(item)
	items[copy.itemId] = copy
	boundedInsert(itemOrder, copy.itemId, Types.Limits.MaxItems)
	if #itemOrder == Types.Limits.MaxItems then
		for id in pairs(items) do
			local found = false
			for _, retainedId in ipairs(itemOrder) do
				if retainedId == id then
					found = true
					break
				end
			end
			if not found then
				removeItem(id)
			end
		end
	end

	ownership[copy.itemId] = {
		itemId = copy.itemId,
		ownerSystem = copy.ownerSystem,
		slotId = copy.slotId,
	}
	if copy.eligibility ~= nil then
		eligibility[copy.itemId] = Serialization.deepCopy(copy.eligibility)
	end

	return true, nil
end

function Runtime.recordValidationFailure(reason: string, payload: any?)
	boundedInsert(validationFailures, {
		reason = reason,
		payload = Serialization.diagnosticCopy(payload),
	}, Types.Limits.MaxValidationFailures)
end

function Runtime.recordSnapshot(snapshot: any)
	boundedInsert(
		snapshotHistory,
		Serialization.diagnosticCopy(snapshot),
		Types.Limits.MaxSnapshotHistory
	)
end

function Runtime.inspect()
	return Serialization.deepCopy({
		profiles = profiles,
		profileOrder = profileOrder,
		items = items,
		itemOrder = itemOrder,
		slots = slots,
		ownership = ownership,
		capacity = capacity,
		eligibility = eligibility,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			profiles = countMap(profiles),
			items = countMap(items),
			slots = countMap(slots),
			ownership = countMap(ownership),
			capacity = countMap(capacity),
			eligibility = countMap(eligibility),
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function Runtime.clear()
	table.clear(profiles)
	table.clear(profileOrder)
	table.clear(items)
	table.clear(itemOrder)
	table.clear(slots)
	table.clear(ownership)
	table.clear(capacity)
	table.clear(eligibility)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return Runtime
