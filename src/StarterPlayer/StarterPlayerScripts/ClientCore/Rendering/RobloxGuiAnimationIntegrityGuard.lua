--!strict

local Guard = {}

function Guard.verify(
	active: { [string]: any },
	propertyOwners: { [string]: string },
	ledger: any
): (boolean, string?)
	local ledgerOk, ledgerReason = ledger.verify(active)
	if not ledgerOk then
		return false, ledgerReason
	end
	for key, animationId in pairs(propertyOwners) do
		local recordData = active[animationId]
		if not recordData then
			return false, "OrphanPropertyOwner:" .. key
		end
		local expected = false
		for _, propertyName in ipairs(recordData.properties) do
			if key == recordData.nodeId .. ":" .. propertyName then
				expected = true
				break
			end
		end
		if not expected then
			return false, "PropertyOwnerMismatch:" .. key
		end
	end
	for animationId, recordData in pairs(active) do
		for _, propertyName in ipairs(recordData.properties) do
			local key = recordData.nodeId .. ":" .. propertyName
			if propertyOwners[key] ~= animationId then
				return false, "PropertyReservationMissing:" .. key
			end
		end
	end
	return true
end

return Guard
