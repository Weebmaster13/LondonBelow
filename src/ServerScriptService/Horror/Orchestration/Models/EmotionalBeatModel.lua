--!strict
-- Protects emotional beats from noisy horror pressure.

local Model = {}

function Model.evaluate(request: any)
	local metadata = request.metadata or {}
	if metadata.emotionalBeat == true then
		return true, { "emotional beat protection active" }
	end
	if metadata.majorReveal == true then
		return true, { "major reveal protection active" }
	end
	return false, {}
end

return Model
