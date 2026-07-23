--!strict

local Metrics = require(script.Parent.RenderingMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Validator = {}

local function countFields(value: any, depth: number?): (boolean, string?)
	if type(value) ~= "table" then
		return true, nil
	end
	local currentDepth = depth or 0
	if currentDepth > Types.RenderingContractLimits.MaxDescriptorDepth then
		return false, "descriptor depth exceeds limit"
	end
	local count = 0
	for key, nested in pairs(value) do
		count += 1
		if count > Types.RenderingContractLimits.MaxDescriptorFields then
			return false, "descriptor field count exceeds limit"
		end
		if type(key) ~= "string" and type(key) ~= "number" then
			return false, "descriptor contains unsupported key type"
		end
		local ok, reason = countFields(nested, currentDepth + 1)
		if not ok then
			return false, reason
		end
	end
	return true, nil
end

function Validator.validate(descriptor: any, renderingKind: string): (boolean, string?)
	if not Types.isRenderingKind(renderingKind) then
		return false, "invalid rendering kind"
	end
	if type(descriptor) ~= "table" then
		return false, "descriptor must be a table"
	end
	local serializable, reason = Serialization.validateSerializable(descriptor)
	if not serializable then
		return false, reason
	end
	local bounded, boundedReason = countFields(descriptor)
	if not bounded then
		return false, boundedReason
	end
	Metrics.increment("descriptorsValidated")
	return true, nil
end

return Validator
