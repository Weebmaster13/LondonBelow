--!strict
-- Slot schema validation helper. Slots describe capacity locations only.

local Validation = require(script.Parent.InventoryValidation)

local InventorySlotRuntime = {}

function InventorySlotRuntime.validate(slots: any): (boolean, string?)
	return Validation.slots(slots)
end

return InventorySlotRuntime
