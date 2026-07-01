--!strict
-- Bounded identity percentage runtime. It owns numbers only, not canon or UI.

local Validation = require(script.Parent.SaveValidation)

local Identity = {}
local identityByProfile: { [string]: number } = {}

local function clamp(value: number): number
	return math.clamp(value, 0, 100)
end

function Identity.set(profileId: string, value: number): (boolean, string?, number?)
	local ok, reason = Validation.identityDelta(profileId, value)
	if not ok then
		return false, reason, nil
	end
	identityByProfile[profileId] = clamp(value)
	return true, nil, identityByProfile[profileId]
end

function Identity.adjust(profileId: string, amount: number): (boolean, string?, number?)
	local ok, reason = Validation.identityDelta(profileId, amount)
	if not ok then
		return false, reason, nil
	end
	identityByProfile[profileId] = clamp((identityByProfile[profileId] or 0) + amount)
	return true, nil, identityByProfile[profileId]
end

function Identity.get(profileId: string): number
	return identityByProfile[profileId] or 0
end

function Identity.clear()
	table.clear(identityByProfile)
end

function Identity.inspect()
	local count = 0
	for _ in pairs(identityByProfile) do
		count += 1
	end
	return {
		identityCount = count,
		identityByProfile = table.clone(identityByProfile),
	}
end

return Identity
