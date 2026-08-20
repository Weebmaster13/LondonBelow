--!strict

local Ledger = {}
local created = 0
local disconnected = 0
local activeConnections = {}

function Ledger.connected(animationId: string)
	if activeConnections[animationId] then
		return false
	end
	activeConnections[animationId] = true
	created += 1
	return true
end

function Ledger.disconnected(animationId: string)
	if not activeConnections[animationId] then
		return false
	end
	activeConnections[animationId] = nil
	disconnected += 1
	return true
end

function Ledger.verify(active: { [string]: any }): (boolean, string?)
	local activeCount = 0
	for animationId, recordData in pairs(active) do
		activeCount += 1
		if recordData.connection == nil or not activeConnections[animationId] then
			return false, "ActiveConnectionMissing:" .. animationId
		end
	end
	local ledgerCount = 0
	for animationId in pairs(activeConnections) do
		ledgerCount += 1
		if not active[animationId] then
			return false, "OrphanConnection:" .. animationId
		end
	end
	if activeCount ~= ledgerCount or created - disconnected ~= ledgerCount then
		return false, "ConnectionBalanceMismatch"
	end
	return true
end

function Ledger.snapshot()
	local ids = {}
	for animationId in pairs(activeConnections) do
		ids[#ids + 1] = animationId
	end
	table.sort(ids)
	return table.freeze({
		created = created,
		disconnected = disconnected,
		active = #ids,
		activeAnimationIds = table.freeze(ids),
		balanced = created - disconnected == #ids,
	})
end

return Ledger
