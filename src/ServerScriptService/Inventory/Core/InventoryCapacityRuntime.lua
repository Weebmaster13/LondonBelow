--!strict
-- Capacity schema validation. Capacity is descriptive and never enforces UI or pickup behavior.

local Validation = require(script.Parent.InventoryValidation)

local InventoryCapacityRuntime = {}

function InventoryCapacityRuntime.validate(capacity: any): (boolean, string?)
	return Validation.capacity(capacity)
end

return InventoryCapacityRuntime
