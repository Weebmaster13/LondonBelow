--!strict
-- Eligibility schema validation. Eligibility records inform future systems but do not execute items.

local Validation = require(script.Parent.InventoryValidation)

local InventoryEligibilityRuntime = {}

function InventoryEligibilityRuntime.validate(eligibility: any): (boolean, string?)
	if type(eligibility) ~= "table" then
		return false, "eligibility must be a table"
	end
	return Validation.safePayload(eligibility)
end

return InventoryEligibilityRuntime
