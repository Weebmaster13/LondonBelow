--!strict
-- Request validation facade.

local Validator = require(script.Parent.Parent.Core.HorrorOrchestrationValidator)

local HorrorPressureValidator = {}

function HorrorPressureValidator.validate(request: any, currentTime: number)
	return Validator.validateRequest(request, currentTime)
end

return HorrorPressureValidator
