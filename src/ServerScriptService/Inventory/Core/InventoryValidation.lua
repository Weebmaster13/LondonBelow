--!strict
-- Validation boundary for server-owned inventory schemas.

local Serialization = require(script.Parent.InventorySerialization)
local Types = require(script.Parent.InventoryTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"animation",
	"audio",
	"camera",
	"chapter",
	"chapter0",
	"chapter1",
	"client",
	"cutscene",
	"dialogue",
	"doorUnlock",
	"execute",
	"gameplayExecution",
	"horrorPacing",
	"instance",
	"itemUseExecution",
	"lighting",
	"monsterAI",
	"narrative",
	"pickupExecution",
	"puzzleSolve",
	"remote",
	"save",
	"savePersistence",
	"story",
	"ui",
	"workspace",
}

local FORBIDDEN_LOOKUP: { [string]: boolean } = {}

for _, field in ipairs(FORBIDDEN_FIELDS) do
	FORBIDDEN_LOOKUP[string.lower(field)] = true
end

local function validId(value: any): boolean
	return type(value) == "string"
		and value ~= ""
		and #value <= 140
		and string.match(value, "^[%w%._%-:]+$") ~= nil
end

local function supportedProfileKind(value: any): boolean
	for _, kind in pairs(Types.ProfileKind) do
		if value == kind then
			return true
		end
	end
	return false
end

local function supportedItemType(value: any): boolean
	for _, itemType in pairs(Types.ItemType) do
		if value == itemType then
			return true
		end
	end
	return false
end

local function forbidden(payload: any, depth: number): (boolean, string?)
	if type(payload) ~= "table" then
		return true, nil
	end
	if depth > Types.Limits.MaxPayloadDepth then
		return false, "inventory payload depth exceeds limit"
	end
	for key in pairs(payload) do
		if type(key) == "string" and FORBIDDEN_LOOKUP[string.lower(key)] == true then
			return false, "inventory payload contains forbidden field: " .. key
		end
	end
	for _, nested in pairs(payload) do
		local ok, reason = forbidden(nested, depth + 1)
		if not ok then
			return false, reason
		end
	end
	return true, nil
end

local function validateTags(tags: any): (boolean, string?)
	if tags == nil then
		return true, nil
	end
	if type(tags) ~= "table" then
		return false, "tags must be a table"
	end
	if #tags > Types.Limits.MaxTags then
		return false, "tag count exceeds limit"
	end
	for _, tag in ipairs(tags) do
		if not validId(tag) then
			return false, "tag is invalid"
		end
		if FORBIDDEN_LOOKUP[string.lower(tag)] == true then
			return false, "tag uses forbidden ownership domain: " .. tag
		end
	end
	return true, nil
end

function Validation.safePayload(payload: any): (boolean, string?)
	local ok, reason = Serialization.validateSerializable(payload)
	if not ok then
		return false, reason
	end
	return forbidden(payload, 0)
end

function Validation.id(value: any): boolean
	return validId(value)
end

function Validation.capacity(capacity: any): (boolean, string?)
	if type(capacity) ~= "table" then
		return false, "capacity must be a table"
	end
	local safe, reason = Validation.safePayload(capacity)
	if not safe then
		return false, reason
	end
	if
		type(capacity.maxSlots) ~= "number"
		or capacity.maxSlots < 0
		or capacity.maxSlots > Types.Limits.MaxCapacity
	then
		return false, "capacity maxSlots is invalid"
	end
	return true, nil
end

function Validation.slots(slots: any): (boolean, string?)
	if type(slots) ~= "table" then
		return false, "slots must be a table"
	end
	if #slots > Types.Limits.MaxSlotsPerProfile then
		return false, "slot count exceeds limit"
	end
	local seen: { [string]: boolean } = {}
	for _, slot in ipairs(slots) do
		if type(slot) ~= "table" or not validId(slot.slotId) then
			return false, "malformed slot"
		end
		if seen[slot.slotId] == true then
			return false, "duplicate slotId"
		end
		seen[slot.slotId] = true
	end
	return Validation.safePayload(slots)
end

function Validation.profile(profile: any): (boolean, string?)
	if type(profile) ~= "table" then
		return false, "inventory profile must be a table"
	end
	local safe, safeReason = Validation.safePayload(profile)
	if not safe then
		return false, safeReason
	end
	if not validId(profile.inventoryProfileId) then
		return false, "inventoryProfileId is required"
	end
	if not validId(profile.ownerSystem) then
		return false, "ownerSystem is required"
	end
	if not supportedProfileKind(profile.profileKind) then
		return false, "unsupported profile type"
	end
	local capacityOk, capacityReason = Validation.capacity(profile.capacity)
	if not capacityOk then
		return false, capacityReason
	end
	local slotsOk, slotsReason = Validation.slots(profile.slots)
	if not slotsOk then
		return false, slotsReason
	end
	local tagsOk, tagsReason = validateTags(profile.tags)
	if not tagsOk then
		return false, tagsReason
	end
	return true, nil
end

function Validation.item(item: any): (boolean, string?)
	if type(item) ~= "table" then
		return false, "item schema must be a table"
	end
	local safe, safeReason = Validation.safePayload(item)
	if not safe then
		return false, safeReason
	end
	if not validId(item.itemId) then
		return false, "itemId is required"
	end
	if not supportedItemType(item.itemType) then
		return false, "unsupported item type"
	end
	if not validId(item.ownerSystem) then
		return false, "ownerSystem is required"
	end
	if not validId(item.slotId) then
		return false, "slotId is required"
	end
	if item.state ~= nil and type(item.state) ~= "table" then
		return false, "item state must be a table"
	end
	if item.eligibility ~= nil and type(item.eligibility) ~= "table" then
		return false, "item eligibility must be a table"
	end
	local tagsOk, tagsReason = validateTags(item.tags)
	if not tagsOk then
		return false, tagsReason
	end
	return true, nil
end

function Validation.validate(): (boolean, string?)
	if Types.Mode ~= "ServerAuthoritativeInventorySchemaRuntime" then
		return false, "Inventory Runtime must remain server-authoritative schema runtime"
	end
	return true, nil
end

return Validation
