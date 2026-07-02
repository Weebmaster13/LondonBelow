--!strict
-- Ownership schema validation. This runtime never grants gameplay ownership.

local Validation = require(script.Parent.InventoryValidation)

local InventoryOwnershipRuntime = {}

function InventoryOwnershipRuntime.validate(record: any): (boolean, string?)
	if type(record) ~= "table" then
		return false, "ownership record must be a table"
	end
	if
		not Validation.id(record.itemId)
		or not Validation.id(record.ownerSystem)
		or not Validation.id(record.slotId)
	then
		return false, "ownership record identity fields are invalid"
	end
	return Validation.safePayload(record)
end

return InventoryOwnershipRuntime
