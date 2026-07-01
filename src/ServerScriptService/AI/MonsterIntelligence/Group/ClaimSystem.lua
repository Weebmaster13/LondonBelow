--!strict
-- Bounded shared claim registry for future coordinated investigations.

local Config = require(script.Parent.Parent.Core.MonsterConfig)

local ClaimSystem = {}

local claims: { [string]: any } = {}
local order: { string } = {}

local function now(): number
	return os.clock()
end

local function trim()
	while #order > Config.MaxClaims do
		local removed = table.remove(order, 1)
		if removed ~= nil then
			claims[removed] = nil
		end
	end
end

function ClaimSystem.claim(monsterId: string, targetId: string, reason: string): (boolean, string?)
	if monsterId == "" or targetId == "" then
		return false, "claim requires monsterId and targetId"
	end
	if claims[targetId] ~= nil then
		return false, "duplicate claim"
	end
	claims[targetId] = {
		monsterId = monsterId,
		targetId = targetId,
		reason = reason,
		createdAt = now(),
		expiresAt = now() + Config.ClaimTimeoutSeconds,
	}
	table.insert(order, targetId)
	trim()
	return true, nil
end

function ClaimSystem.release(targetId: string): boolean
	if claims[targetId] == nil then
		return false
	end
	claims[targetId] = nil
	for index = #order, 1, -1 do
		if order[index] == targetId then
			table.remove(order, index)
			break
		end
	end
	return true
end

function ClaimSystem.cleanupExpired(): number
	local currentTime = now()
	local expired = 0
	for index = #order, 1, -1 do
		local targetId = order[index]
		local claim = claims[targetId]
		if claim == nil or claim.expiresAt <= currentTime then
			claims[targetId] = nil
			table.remove(order, index)
			expired += 1
		end
	end
	return expired
end

function ClaimSystem.clear()
	table.clear(claims)
	table.clear(order)
end

function ClaimSystem.inspect()
	return {
		claimCount = #order,
		limit = Config.MaxClaims,
		claims = table.clone(claims),
	}
end

return ClaimSystem
