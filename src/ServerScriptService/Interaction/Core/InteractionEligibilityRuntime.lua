--!strict
-- Eligibility schema helpers for interaction objects.

local Validation = require(script.Parent.InteractionValidation)

local Eligibility = {}

function Eligibility.validate(eligibility: any): (boolean, string?)
	if eligibility == nil then
		return true, nil
	end
	if type(eligibility) ~= "table" then
		return false, "eligibility must be a table"
	end
	return Validation.safePayload(eligibility)
end

return Eligibility
