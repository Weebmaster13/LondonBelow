--!strict

local Certification = require(script.Parent.CommandCertification)
local Serialization = require(script.Parent.CommandSerialization)

local Integrity = {}

function Integrity.calculate(signals: any)
	local score = 0
	local total = 0
	for _, value in pairs(signals) do
		total += 1
		if value == true then
			score += 1
		end
	end
	return Serialization.deepCopy({
		score = if total > 0 then math.floor((score / total) * 100) else 0,
		status = Certification.inspect().status,
		informationalOnly = true,
		inputs = signals,
	})
end

return Integrity
